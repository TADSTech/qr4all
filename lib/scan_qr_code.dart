// scan_qr_code.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr4all/qr_data_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart';
import 'package:qr4all/platform_utils.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({super.key});

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  String qrResult = 'Scan result will appear here';
  MobileScannerController cameraController = MobileScannerController(
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );
  bool isScanning = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  String _scanStatus = 'Initializing...';
  bool _continuousScan = true;
  bool _beepOnScan = true;
  bool _hasCamera = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _scanCooldownTimer;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _loadSound();
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    if (!kIsWeb) {
      final granted = await PlatformUtils.requestCameraPermission();
      if (!granted) {
        setState(() {
          _scanStatus = 'Camera permission denied. Cannot scan.';
        });
        _showPermissionDeniedDialog('camera');
      }
    }
  }

  Future<void> _initializeScanner() async {
    try {
      _hasCamera = await _checkCameraAvailability();

      if (_hasCamera) {
        _updateState(() => _scanStatus = 'Ready to scan');
        _updateState(() {
          isScanning = true;
        });
        cameraController.start();
      } else {
        _updateState(() => _scanStatus = 'No camera detected');
      }
    } catch (e) {
      _updateState(() => _scanStatus = 'Camera initialization failed');
      debugPrint('Camera init error: $e');
    }
  }

  Future<bool> _checkCameraAvailability() async {
    if (kIsWeb) return true;

    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      debugPrint('Camera check error: $e');
      return false;
    }
  }

  Future<void> _loadSound() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Error loading sound: $e');
    }
  }

  @override
  void dispose() {
    _scanCooldownTimer?.cancel();
    cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  Future<void> _saveScan(String result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentScans = prefs.getStringList('recentScans') ?? [];
    recentScans.insert(0, result);
    if (recentScans.length > 10) {
      recentScans = recentScans.sublist(0, 10);
    }
    await prefs.setStringList('recentScans', recentScans);
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: qrResult));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleBarcode(BarcodeCapture barcode) {
    if (_isProcessing) return;
    _isProcessing = true;

    final String? code = barcode.barcodes.firstOrNull?.rawValue;

    if (code == null || code.isEmpty) {
      _isProcessing = false;
      return;
    }

    _updateState(() {
      qrResult = code;
      _scanStatus = 'Scan successful!';
    });

    _saveScan(code);
    _handleTaggedAction(code);

    if (_beepOnScan) {
      _playBeepSound();
    }

    if (!_continuousScan) {
      _updateState(() {
        isScanning = false;
        cameraController.stop();
      });
    } else {
      _scanCooldownTimer?.cancel();
      _scanCooldownTimer = Timer(const Duration(seconds: 1), () {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleTaggedAction(String code) async {
    if (code.startsWith('QR4ALL:')) {
      final parts = code.split(':');
      if (parts.length >= 3) {
        final type = parts[1];
        final data = parts.sublist(2).join(':');

        final qrType = QRDataHandler.getTypeByName(type);
        if (qrType != null && qrType.hasAction) {
          await qrType.action!(context, data);
          return;
        }
      }
    }

    if (Uri.tryParse(code)?.hasAbsolutePath ?? false) {
      await QRDataHandler.doLaunchUrl(code);
    }
  }

  Future<void> _playBeepSound() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error playing beep sound: $e');
    }
  }

  Future<void> _handleImageUpload() async {
    if (_isProcessing) return;
    _isProcessing = true;

    _updateState(() {
      _scanStatus = 'Processing image...';
    });

    try {
      final Uint8List? imageBytes = await _pickImage();
      if (imageBytes == null) {
        _updateState(() {
          _scanStatus = 'Image selection canceled';
          _isProcessing = false;
        });
        return;
      }

      final result = await _decodeQrFromImage(imageBytes);
      _updateState(() {
        qrResult = result ?? 'No QR code found in image';
        _scanStatus =
            result != null ? 'Decoding successful' : 'No QR code detected';
      });

      if (result != null) {
        await _saveScan(result);
        _handleTaggedAction(result);
        if (_beepOnScan) {
          await _playBeepSound();
        }
      }
    } catch (e) {
      _updateState(() {
        qrResult = 'Error processing image: ${e.toString()}';
        _scanStatus = 'Decoding failed';
      });
    } finally {
      _isProcessing = false;
    }
  }

  Future<Uint8List?> _pickImage() async {
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final completer = Completer<Uint8List?>();
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final file = uploadInput.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            completer.complete(reader.result as Uint8List?);
          });
        } else {
          completer.complete(null);
        }
      });

      return completer.future;
    } else {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    }
  }

  Future<String?> _decodeQrFromImage(Uint8List imageBytes) async {
    String? decodedResult;

    try {
      decodedResult = await _decodeQrFromWebAPI(imageBytes);
    } catch (e) {
      debugPrint('Web QR decode failed: $e');
    }

    return decodedResult;
  }

  Future<String?> _decodeQrFromWebAPI(Uint8List imageBytes) async {
    const String apiUrl = 'https://api.qrserver.com/v1/read-qr-code/';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
            filename: 'qr.png'));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        List<dynamic> jsonResponse = jsonDecode(responseData);

        if (jsonResponse.isNotEmpty &&
            jsonResponse[0]['symbol'] != null &&
            jsonResponse[0]['symbol'].isNotEmpty) {
          return jsonResponse[0]['symbol'][0]['data'];
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to decode QR code: ${e.toString()}');
    }
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
            'Camera permission is required to scan QR codes. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PlatformUtils.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        actions: [
          if (cameraController.hasTorch)
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              onPressed: () {
                _updateState(() {
                  _isTorchOn = !_isTorchOn;
                  cameraController.toggleTorch();
                });
              },
              tooltip: 'Toggle torch',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScannerSection(context),
              const SizedBox(height: 16),
              _buildResultSection(context),
              const SizedBox(height: 16),
              _buildControlButtons(context),
              const SizedBox(height: 8),
              _buildStatusIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (_hasCamera)
                MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            size: 60, color: Colors.white54),
                        const SizedBox(height: 16),
                        Text(
                          _hasCamera
                              ? 'Camera preview inactive'
                              : 'No camera available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        if (!_hasCamera) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _handleImageUpload,
                            child: const Text('Upload Image Instead'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (isScanning && _hasCamera)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align QR code within frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: BoxConstraints(
                minHeight: 100,
                maxHeight: MediaQuery.of(context).size.height * 0.2,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  qrResult,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (qrResult.startsWith('QR4ALL:'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleTaggedAction(qrResult),
                    child: Text(
                      'Perform Action',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            if (_hasCamera)
              _buildActionButton(
                icon: isScanning ? Icons.stop : Icons.camera_alt,
                label: isScanning ? 'Stop' : 'Scan',
                onPressed: () {
                  _updateState(() {
                    isScanning = !isScanning;
                    if (!isScanning) {
                      cameraController.stop();
                    } else {
                      _scanStatus = 'Scanning...';
                    }
                  });
                },
              ),
            _buildActionButton(
              icon: Icons.upload,
              label: 'Upload Image',
              onPressed: _handleImageUpload,
            ),
            if (cameraController.hasTorch)
              _buildActionButton(
                icon: _isTorchOn ? Icons.flash_off : Icons.flash_on,
                label: _isTorchOn ? 'Torch Off' : 'Torch On',
                onPressed: () {
                  _updateState(() {
                    _isTorchOn = !_isTorchOn;
                    cameraController.toggleTorch();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOptionsButton(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon, size: 28),
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsButton() {
    return TextButton.icon(
      icon: const Icon(Icons.settings, size: 20),
      label: const Text('Scan Options'),
      onPressed: _showScanOptions,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _scanStatus,
        style: TextStyle(
          color: _scanStatus.contains('failed') || _scanStatus.contains('No QR')
              ? Colors.red
              : _scanStatus.contains('success')
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showScanOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Continuous Scan'),
              value: _continuousScan,
              onChanged: (value) {
                _updateState(() {
                  _continuousScan = value;
                });
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Beep on Scan'),
              value: _beepOnScan,
              onChanged: (value) {
                _updateState(() {
                  _beepOnScan = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
