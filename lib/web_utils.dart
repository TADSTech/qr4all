// lib/web_utils.dart
import 'dart:html' as html;
import 'dart:typed_data';

class WebUtils {
  static Future<void> shareQRCodeWeb(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> downloadQRCodeWeb(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void scanFromImageWeb(void Function(Uint8List) onImageSelected) {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          onImageSelected(reader.result as Uint8List);
        });
      }
    });
  }
}
