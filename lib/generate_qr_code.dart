import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // For RenderRepaintBoundary
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'web_utils.dart' if (dart.library.io) 'mobile_utils.dart';

class GenerateQrCode extends StatefulWidget {
  const GenerateQrCode({super.key});

  @override
  State<GenerateQrCode> createState() => _GenerateQrCodeState();
}

class _GenerateQrCodeState extends State<GenerateQrCode> {
  final TextEditingController _controller = TextEditingController();
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _quietZone = 10.0;
  int _errorCorrectionLevel = QrErrorCorrectLevel.L;
  final GlobalKey _qrKey = GlobalKey();
  String _selectedDataType = 'Text'; // Default data type

  final List<String> _dataTypes = ['Text', 'URL', 'Email', 'Phone'];

  void _generateQRCode() => setState(() {});

  Future<void> _shareQRCode() async {
    if (_controller.text.isEmpty) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null || !boundary.attached) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) return;

      if (kIsWeb) {
        await WebUtils.shareQRCodeWeb(byteData.buffer.asUint8List());
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/qr_code.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        await Share.shareXFiles([XFile(file.path)], text: 'Check out this QR code!');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share QR code: ${e.toString()}')),
      );
    }
  }

  Future<void> _downloadQRCode() async {
    if (_controller.text.isEmpty) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null || !boundary.attached) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData == null) return;

      if (kIsWeb) {
        await WebUtils.downloadQRCodeWeb(byteData.buffer.asUint8List());
      } else {
        final directory = await getDownloadsDirectory();
        final file =
            File('${directory?.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR code saved to ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR code: ${e.toString()}')),
      );
    }
  }

  String _formatData() {
    switch (_selectedDataType) {
      case 'URL':
        return _controller.text.startsWith('http')
            ? _controller.text
            : 'https://${_controller.text}';
      case 'Email':
        return 'mailto:${_controller.text}';
      case 'Phone':
        return 'tel:${_controller.text}';
      default:
        return _controller.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 8,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 32.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Data Type Selection
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Select Data Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: _dataTypes.map((type) {
                            return ChoiceChip(
                              label: Text(type),
                              selected: _selectedDataType == type,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDataType = type;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Input Section
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: 'Enter $_selectedDataType',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () => _controller.clear(),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              icon: Icons.qr_code,
                              label: 'Generate',
                              onPressed: _generateQRCode,
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onPressed: _shareQRCode,
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            _buildActionButton(
                              icon: Icons.download,
                              label: 'Download',
                              onPressed: _downloadQRCode,
                            ),
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // QR Code Display Section
                if (_controller.text.isNotEmpty)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: _qrKey,
                            child: QrImageView(
                              data: _formatData(),
                              version: QrVersions.auto,
                              size: isLargeScreen ? 300 : 200,
                              backgroundColor: _backgroundColor,
                              foregroundColor: _qrColor,
                              gapless: false,
                              padding: EdgeInsets.all(_quietZone),
                              errorCorrectionLevel: _errorCorrectionLevel,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildColorPickerSection(),
                          const SizedBox(height: 20),
                          _buildAdvancedSettingsSection(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label, style: TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(150, 50),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildColorPickerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColorPickerButton(
          label: 'QR Color',
          color: _qrColor,
          onColorChanged: (color) => setState(() => _qrColor = color),
        ),
        _buildColorPickerButton(
          label: 'Background',
          color: _backgroundColor,
          onColorChanged: (color) => setState(() => _backgroundColor = color),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Column(
      children: [
        Text('Advanced Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        _buildSlider(
          label: 'Quiet Zone',
          value: _quietZone,
          min: 0,
          max: 20,
          onChanged: (value) => setState(() => _quietZone = value),
        ),
        _buildDropdown(
          label: 'Error Correction',
          value: _errorCorrectionLevel,
          items: [
            DropdownMenuItem(
              value: QrErrorCorrectLevel.L,
              child: Text('Low (L)'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.M,
              child: Text('Medium (M)'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.Q,
              child: Text('Quartile (Q)'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.H,
              child: Text('High (H)'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _errorCorrectionLevel = value ?? QrErrorCorrectLevel.L),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toStringAsFixed(1)}'),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButton<int>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerButton({
    required String label,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ColorPickerButton(
          initialColor: color,
          onColorChanged: onColorChanged,
        ),
      ],
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const ColorPickerButton({
    required this.initialColor,
    required this.onColorChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: initialColor,
              onColorChanged: onColorChanged,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: initialColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
