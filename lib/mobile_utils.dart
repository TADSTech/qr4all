import 'dart:typed_data';

// lib/mobile_utils.dart
class WebUtils {
  static Future<void> shareQRCodeWeb(Uint8List byteData) async {
    throw UnsupportedError('WebUtils.shareQRCodeWeb is not supported on mobile.');
  }

  static Future<void> downloadQRCodeWeb(Uint8List byteData) async {
    throw UnsupportedError('WebUtils.downloadQRCodeWeb is not supported on mobile.');
  }

  static void scanFromImageWeb(void Function(Uint8List) onImageSelected) {
    throw UnsupportedError('WebUtils.scanFromImageWeb is not supported on mobile.');
  }
}
