import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr4all/platform_utils.dart';

class GenerateQrCode extends StatefulWidget {
  const GenerateQrCode({super.key});

  @override
  State<GenerateQrCode> createState() => _GenerateQrCodeState();
}

class _GenerateQrCodeState extends State<GenerateQrCode> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _quietZone = 10.0;
  int _errorCorrectionLevel = QrErrorCorrectLevel.L;
  String _selectedDataType = 'Text';
  bool _includeTag = true;

  final List<Map<String, dynamic>> _dataTypes = [
    {
      'name': 'Text',
      'icon': Icons.text_fields,
      'hint': 'Enter your text',
      'validator': (value) => value.isNotEmpty ? null : 'Please enter text',
    },
    {
      'name': 'URL',
      'icon': Icons.link,
      'hint': 'Enter URL (https://)',
      'validator': (value) => value.isNotEmpty ? null : 'Please enter a URL',
      'formatter': (value) =>
          value.startsWith('http') ? value : 'https://$value',
    },
    {
      'name': 'Email',
      'icon': Icons.email,
      'hint': 'Enter email address',
      'validator': (value) =>
          value.contains('@') ? null : 'Please enter a valid email',
      'formatter': (value) => 'mailto:$value',
    },
    {
      'name': 'Phone',
      'icon': Icons.phone,
      'hint': 'Enter phone number',
      'validator': (value) =>
          value.isNotEmpty ? null : 'Please enter a phone number',
      'formatter': (value) => 'tel:$value',
    },
    {
      'name': 'SMS',
      'icon': Icons.sms,
      'hint': 'Enter phone number',
      'validator': (value) =>
          value.isNotEmpty ? null : 'Please enter a phone number',
      'formatter': (value) => 'sms:$value',
    },
    {
      'name': 'WiFi',
      'icon': Icons.wifi,
      'hint': 'Enter network details',
      'validator': (value) =>
          value.isNotEmpty ? null : 'Please enter network details',
      'formatter': (value) => 'WIFI:T:WPA;S:$value;P:;H:;',
    },
    {
      'name': 'Contact',
      'icon': Icons.contact_page,
      'hint': 'Enter contact info',
      'validator': (value) =>
          value.isNotEmpty ? null : 'Please enter contact info',
      'formatter': (value) => 'MECARD:N:$value;TEL:;EMAIL:;ADR:;;',
    },
    {
      'name': 'Location',
      'icon': Icons.location_on,
      'hint': 'Enter coordinates (lat,long)',
      'validator': (value) =>
          value.contains(',') ? null : 'Please enter coordinates as lat,long',
      'formatter': (value) => 'geo:$value',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateQRCode() => setState(() {});

  Future<void> _shareQRCode() async {
    if (_controller.text.isEmpty) return;

    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      await PlatformUtils.shareQRCode(byteData.buffer.asUint8List());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share QR code: ${e.toString()}')),
      );
    }
  }

  Future<void> _downloadQRCode() async {
    if (_controller.text.isEmpty) return;

    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.attached) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      await PlatformUtils.downloadQRCode(byteData.buffer.asUint8List());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR code: ${e.toString()}')),
      );
    }
  }

  String _formatData() {
    final currentType =
        _dataTypes.firstWhere((type) => type['name'] == _selectedDataType);
    final formatter = currentType['formatter'] as Function(String)?;
    final rawText = _controller.text;
    final formattedText = formatter != null ? formatter(rawText) : rawText;

    return _includeTag
        ? 'QR4ALL:${currentType['name']}:$formattedText'
        : formattedText;
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 8,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Data Type Selection Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Select Data Type',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dataTypes.map((type) {
                            return FilterChip(
                              label: Text(type['name']),
                              avatar: Icon(type['icon'], size: 20),
                              selected: _selectedDataType == type['name'],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedDataType = type['name'];
                                  _controller.text = '';
                                });
                              },
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: _selectedDataType == type['name']
                                    ? theme.colorScheme.onPrimary
                                    : null,
                              ),
                              selectedColor: theme.colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Include App Tag'),
                          subtitle: const Text(
                              'Adds QR4ALL tag for better scanning in our app'),
                          value: _includeTag,
                          onChanged: (value) =>
                              setState(() => _includeTag = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Input Section
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: _dataTypes.firstWhere((type) =>
                                type['name'] == _selectedDataType)['hint'],
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _controller.clear(),
                            ),
                            prefixIcon: Icon(_dataTypes.firstWhere((type) =>
                                type['name'] == _selectedDataType)['icon']),
                          ),
                          maxLines: _selectedDataType == 'Text' ? 3 : 1,
                          validator: _dataTypes.firstWhere((type) =>
                              type['name'] == _selectedDataType)['validator'],
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildActionButton(
                              icon: Icons.qr_code,
                              label: 'Generate',
                              onPressed: _generateQRCode,
                              enabled: _controller.text.isNotEmpty,
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onPressed: _shareQRCode,
                              enabled: _controller.text.isNotEmpty,
                            ),
                            _buildActionButton(
                              icon: Icons.download,
                              label: 'Download',
                              onPressed: _downloadQRCode,
                              enabled: _controller.text.isNotEmpty,
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Your QR Code',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 16),
                          RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: _formatData(),
                                version: QrVersions.auto,
                                size: isLargeScreen ? 280 : 200,
                                backgroundColor: _backgroundColor,
                                foregroundColor: _qrColor,
                                gapless: false,
                                padding: EdgeInsets.all(_quietZone),
                                errorCorrectionLevel: _errorCorrectionLevel,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildColorPickerSection(),
                          const SizedBox(height: 16),
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
    required bool enabled,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 48),
        backgroundColor: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
        foregroundColor: enabled
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildColorPickerSection() {
    return Column(
      children: [
        Text('Customization',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 12),
        Row(
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
              onColorChanged: (color) =>
                  setState(() => _backgroundColor = color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Column(
      children: [
        Text('Advanced Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 12),
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
              child: Text('Low (L) - ~7% recovery'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.M,
              child: Text('Medium (M) - ~15% recovery'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.Q,
              child: Text('Quartile (Q) - ~25% recovery'),
            ),
            DropdownMenuItem(
              value: QrErrorCorrectLevel.H,
              child: Text('High (H) - ~30% recovery'),
            ),
          ],
          onChanged: (value) => setState(
              () => _errorCorrectionLevel = value ?? QrErrorCorrectLevel.L),
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
            label: value.toStringAsFixed(1),
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
          DropdownButtonFormField<int>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
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
        Text(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Pick $label'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: color,
                  onColorChanged: onColorChanged,
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                  hexInputBar: true,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Select'),
                ),
              ],
            ),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
