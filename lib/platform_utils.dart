import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb

abstract class PlatformUtils {
  static Future<void> shareQRCode(Uint8List byteData) async {
    if (kIsWeb) {
      // Use kIsWeb for web platform check
      await _shareWeb(byteData);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _shareMobile(byteData);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _shareDesktop(byteData);
    }
  }

  static Future<void> openAppSettings() async {
    if (kIsWeb) {
      print('Cannot open app settings on web.');
      html.window.alert(
          'Please manually adjust permissions in your browser settings.');
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        await openAppSettings();
      } on PlatformException catch (e) {
        print('Error opening app settings on mobile: ${e.code} - ${e.message}');
      } catch (e) {
        print('Unexpected error opening app settings on mobile: $e');
      }
    } else {
      //gonna add snackbars in future updates
      print('Opening app settings is not supported on this platform.');
    }
  }

  static Future<void> downloadQRCode(Uint8List byteData) async {
    if (kIsWeb) {
      // Use kIsWeb for web platform check
      await _downloadWeb(byteData);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _downloadMobile(byteData);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _downloadDesktop(byteData);
    }
  }

  static Future<void> scanFromImage(
      void Function(Uint8List) onImageSelected) async {
    if (kIsWeb) {
      // Use kIsWeb for web platform check
      await _scanFromImageWeb(onImageSelected);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _scanFromImageMobile(onImageSelected);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop image picking implementation (if needed)
    }
  }

  // --- Permission Handling ---
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestStoragePermissions() async {
    if (kIsWeb)
      return true; // Web doesn't need explicit storage permission via permission_handler

    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted &&
          await Permission.videos.request().isGranted &&
          await Permission.audio.request().isGranted) {
        return true;
      } else {
        // For older Android versions (< Android 13)
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
    } else if (Platform.isIOS) {
      var photoStatus = await Permission.photos.status;
      if (!photoStatus.isGranted) {
        photoStatus = await Permission.photos.request();
      }
      return photoStatus.isGranted;
    }
    return false; // For other platforms, assume no specific storage permission needed or handle as appropriate
  }

  static Future<bool> requestAllNecessaryPermissions() async {
    bool cameraGranted = await requestCameraPermission();
    bool storageGranted = await requestStoragePermissions();
    // POTENTIALS to add
    // bool contactsGranted = await Permission.contacts.request().isGranted;
    // bool calendarGranted = await Permission.calendar.request().isGranted;
    return cameraGranted &&
        storageGranted; // && contactsGranted && calendarGranted;
  }

  // --- Mobile Implementations ---
  static Future<void> _shareMobile(Uint8List byteData) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData);

      await Share.shareXFiles([XFile(filePath)], text: 'Check out my QR code!');
    } catch (e) {
      print('Error sharing on mobile: $e');
    }
  }

  static Future<void> _downloadMobile(Uint8List byteData) async {
    try {
      // Request storage permission first
      bool granted = await requestStoragePermissions();
      if (!granted) {
        print('Storage permission not granted. Cannot download.');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData);
      print('QR Code downloaded to: $filePath');
    } catch (e) {
      print('Error downloading on mobile: $e');
    }
  }

  static Future<void> _scanFromImageMobile(
      void Function(Uint8List) onImageSelected) async {
    // Request storage/photos permission before picking image
    bool granted = await requestStoragePermissions();
    if (!granted) {
      print('Storage/Photos permission not granted. Cannot pick image.');
      return;
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final byteData = await image.readAsBytes();
      onImageSelected(byteData);
    }
  }

  // --- Desktop Implementations (placeholders for now) ---
  static Future<void> _shareDesktop(Uint8List byteData) async {
    print('Sharing on desktop is not implemented.');
    // TODO: IMPLEMENT THIS
  }

  static Future<void> _downloadDesktop(Uint8List byteData) async {
    print('Downloading on desktop is not implemented.');
    // TODO: IMPLEMENT THIS
  }

  // --- Web Implementations ---
  static Future<void> _shareWeb(Uint8List byteData) async {
    try {
      final blob = html.Blob([byteData], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png')
        ..click();
      await Future.delayed(Duration(milliseconds: 100));
      html.Url.revokeObjectUrl(url);

      print('QR Code shared/download triggered on web.');
    } catch (e) {
      print('Error sharing on web: $e');
    }
  }

  static Future<void> _downloadWeb(Uint8List byteData) async {
    try {
      final blob = html.Blob([byteData], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a temporary anchor element
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'qr_code_${DateTime.now().millisecondsSinceEpoch}.png') // Suggest a filename
        ..click(); // Programmatically click the anchor to trigger download

      // Revoke the object URL after a short delay to allow download to start
      await Future.delayed(Duration(milliseconds: 100)); // Small delay
      html.Url.revokeObjectUrl(url);

      print('QR Code download initiated on web.');
    } catch (e) {
      print('Error downloading on web: $e');
    }
  }

  static Future<void> _scanFromImageWeb(
      void Function(Uint8List) onImageSelected) async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
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
