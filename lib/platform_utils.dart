import 'dart:typed_data';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

abstract class PlatformUtils {
  static Future<void> shareQRCode(Uint8List byteData) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _shareMobile(byteData);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _shareDesktop(byteData);
    } else {
      await _shareWeb(byteData);
    }
  }

  static Future<void> downloadQRCode(Uint8List byteData) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _downloadMobile(byteData);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _downloadDesktop(byteData);
    } else {
      await _downloadWeb(byteData);
    }
  }

  static Future<void> scanFromImage(
      void Function(Uint8List) onImageSelected) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _scanFromImageMobile(onImageSelected);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _scanFromImageDesktop(onImageSelected);
    } else {
      await _scanFromImageWeb(onImageSelected);
    }
  }

  // Mobile implementations
  static Future<void> _shareMobile(Uint8List byteData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData);
    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<void> _downloadMobile(Uint8List byteData) async {
    final downloadsDir = await getDownloadsDirectory();
    final file = File(
        '${downloadsDir?.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData);
    // On mobile, the file is saved automatically - we can show a confirmation
  }

  static Future<void> _scanFromImageMobile(
      void Function(Uint8List) onImageSelected) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      onImageSelected(bytes);
    }
  }

  // Desktop implementations (similar to web)
  static Future<void> _shareDesktop(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _downloadDesktop(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _scanFromImageDesktop(
      void Function(Uint8List) onImageSelected) async {
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

  // Web implementations
  static Future<void> _shareWeb(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _downloadWeb(Uint8List byteData) async {
    final blob = html.Blob([byteData], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
          'download', 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> _scanFromImageWeb(
      void Function(Uint8List) onImageSelected) async {
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
