import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanQrCode extends StatefulWidget {
  const ScanQrCode({super.key});

  @override
  State<ScanQrCode> createState() => _ScanQrCodeState();
}

class _ScanQrCodeState extends State<ScanQrCode> {
  String qrResult = 'Scan result will appear here';
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _handleBarcode(BarcodeCapture barcode) {
    final String? code = barcode.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      qrResult = code;
      isScanning = false;
    });

    _saveScan(code);
  }

  void _handleBarcodeForWeb() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) async {
          try {
            Uint8List imageBytes = reader.result as Uint8List;
            String? qrText = await _decodeQrFromWebAPI(imageBytes);

            setState(() {
              qrResult = qrText ?? 'No QR code found in image';
            });

            if (qrText != null) {
              await _saveScan(qrText);
            }
          } catch (e) {
            setState(() {
              qrResult = 'Error reading image: ${e.toString()}';
            });
          }
        });
      }
    });
  }

  Future<String?> _decodeQrFromWebAPI(Uint8List imageBytes) async {
    const String apiUrl = 'https://api.qrserver.com/v1/read-qr-code/';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'qr.png'));

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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 8,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: isLargeScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildScannerSection(context),
                        const SizedBox(width: 20),
                        _buildResultSection(context),
                      ],
                    )
                  : Column(
                      children: [
                        _buildScannerSection(context),
                        const SizedBox(height: 20),
                        _buildResultSection(context),
                      ],
                    ),
            ),
            _buildControlButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerSection(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: isScanning
              ? MobileScanner(
                  controller: cameraController,
                  onDetect: _handleBarcode,
                )
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      'Camera preview inactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width > 600 ? 24 : 18,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scan Result',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyToClipboard,
                tooltip: 'Copy to clipboard',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    qrResult,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(
            icon: isScanning ? Icons.stop : Icons.camera_alt,
            label: isScanning ? 'Stop' : 'Scan',
            onPressed: () => setState(() {
              isScanning = !isScanning;
              if (!isScanning) cameraController.stop();
            }),
          ),
          const SizedBox(width: 20),
          _buildIconButton(
            icon: Icons.upload,
            label: 'Upload',
            onPressed: _handleBarcodeForWeb,
          ),
          const SizedBox(width: 20),
          _buildIconButton(
            icon: Icons.lightbulb_outline,
            label: 'Torch',
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 36),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
