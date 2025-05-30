import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' show Platform;

class QRDataHandler {
  static final List<QRDataType> _dataTypes = [
    QRDataType(
      name: 'Text',
      icon: Icons.text_fields,
      hint: 'Enter your text',
      validator: (value) => value.isNotEmpty ? null : 'Please enter text',
      formatter: (value, includeTag) =>
          includeTag ? 'QR4ALL:Text:$value' : value,
    ),
    QRDataType(
      name: 'URL',
      icon: Icons.link,
      hint: 'Enter URL (https://)',
      validator: (value) => value.isNotEmpty ? null : 'Please enter a URL',
      formatter: (value, includeTag) {
        final formatted = value.startsWith('http') ? value : 'https://$value';
        return includeTag ? 'QR4ALL:URL:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await doLaunchUrl(data);
      },
    ),
    QRDataType(
      name: 'Email',
      icon: Icons.email,
      hint: 'Enter email address',
      validator: (value) =>
          value.contains('@') ? null : 'Please enter a valid email',
      formatter: (value, includeTag) {
        final formatted = 'mailto:$value';
        return includeTag ? 'QR4ALL:Email:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await doLaunchUrl(data);
      },
    ),
    QRDataType(
      name: 'Phone',
      icon: Icons.phone,
      hint: 'Enter phone number',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter a phone number',
      formatter: (value, includeTag) {
        final formatted = 'tel:$value';
        return includeTag ? 'QR4ALL:Phone:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await doLaunchUrl(data);
      },
    ),
    QRDataType(
      name: 'SMS',
      icon: Icons.sms,
      hint: 'Enter phone number with optional message (number,message)',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter a phone number',
      formatter: (value, includeTag) {
        final parts = value.split(',');
        final number = parts[0].trim();
        final message = parts.length > 1 ? parts[1].trim() : '';
        final formatted =
            message.isEmpty ? 'sms:$number' : 'sms:$number?body=$message';
        return includeTag ? 'QR4ALL:SMS:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await _launchSms(data);
      },
    ),
    QRDataType(
      name: 'WiFi',
      icon: Icons.wifi,
      hint: 'Enter network details (SSID,Password,Type)',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter network details',
      formatter: (value, includeTag) {
        final parts = value.split(',');
        final ssid = parts[0].trim();
        final password = parts.length > 1 ? parts[1].trim() : '';
        final type = parts.length > 2 ? parts[2].trim() : 'WPA';
        final formatted = 'WIFI:T:$type;S:$ssid;P:$password;;';
        return includeTag ? 'QR4ALL:WiFi:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await _connectToWifi(data);
      },
    ),
    QRDataType(
      name: 'Contact',
      icon: Icons.contact_page,
      hint: 'Enter contact details (Name,Phone,Email,Address)',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter contact info',
      formatter: (value, includeTag) {
        final parts = value.split(',');
        final name = parts[0].trim();
        final phone = parts.length > 1 ? parts[1].trim() : '';
        final email = parts.length > 2 ? parts[2].trim() : '';
        final address = parts.length > 3 ? parts[3].trim() : '';
        final formatted =
            'MECARD:N:$name;TEL:$phone;EMAIL:$email;ADR:$address;;';
        return includeTag ? 'QR4ALL:Contact:$formatted' : formatted;
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await _addContact(data);
      },
    ),
    QRDataType(
      name: 'Location',
      icon: Icons.location_on,
      hint: 'Enter coordinates (lat,long) or address',
      validator: (value) => value.isNotEmpty ? null : 'Please enter location',
      formatter: (value, includeTag) {
        if (value.contains(',')) {
          final formatted = 'geo:$value';
          return includeTag ? 'QR4ALL:Location:$formatted' : formatted;
        } else {
          final formatted = 'geo:0,0?q=${Uri.encodeComponent(value)}';
          return includeTag ? 'QR4ALL:Location:$formatted' : formatted;
        }
      },
      action: (context, data) async {
        if (data.startsWith('QR4ALL:')) {
          data = data.split(':').sublist(2).join(':');
        }
        await doLaunchUrl(data);
      },
    ),
    QRDataType(
      name: 'Event',
      icon: Icons.event,
      hint: 'Enter event details (Title,StartDate,EndDate,Location)',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter event details',
      formatter: (value, includeTag) {
        final parts = value.split(',');
        final title = parts[0].trim();
        final start = parts.length > 1 ? parts[1].trim() : '';
        final end = parts.length > 2 ? parts[2].trim() : '';
        final location = parts.length > 3 ? parts[3].trim() : '';
        final formatted = 'BEGIN:VEVENT\nSUMMARY:$title\nDTSTART:$start\n'
            'DTEND:$end\nLOCATION:$location\nEND:VEVENT';
        return includeTag ? 'QR4ALL:Event:$formatted' : formatted;
      },
    ),
    QRDataType(
      name: 'Cryptocurrency',
      icon: Icons.currency_bitcoin,
      hint: 'Enter crypto details (Currency,Address,Amount,Message)',
      validator: (value) =>
          value.isNotEmpty ? null : 'Please enter crypto details',
      formatter: (value, includeTag) {
        final parts = value.split(',');
        final currency = parts[0].trim();
        final address = parts.length > 1 ? parts[1].trim() : '';
        final amount = parts.length > 2 ? parts[2].trim() : '';
        final message = parts.length > 3 ? parts[3].trim() : '';
        final formatted = '$currency:$address?amount=$amount&message=$message';
        return includeTag ? 'QR4ALL:Crypto:$formatted' : formatted;
      },
    ),
  ];

  static List<QRDataType> get dataTypes => _dataTypes;

  static QRDataType? getTypeByName(String name) {
    try {
      return _dataTypes.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }

  static Future<void> doLaunchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (!Platform.isAndroid && !Platform.isIOS) {
        html.window.open(url, '_blank');
      }
    }
  }

  static Future<void> _launchSms(String data) async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.SENDTO',
          data: Uri.encodeFull(data),
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        await doLaunchUrl(data);
      } else {
        html.window.open(data, '_blank');
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
    }
  }

  static Future<void> _addContact(String vcfData) async {
    try {
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.INSERT',
          type: 'vnd.android.cursor.dir/contact',
          arguments: {
            'name': vcfData
                .split(';')
                .firstWhere(
                  (part) => part.startsWith('N='),
                  orElse: () => 'N=Unknown',
                )
                .substring(2),
          },
        );
        await intent.launch();
      } else if (Platform.isIOS) {
        await doLaunchUrl(
            'https://example.com/contact?vcf=${Uri.encodeComponent(vcfData)}');
      } else {
        final blob = html.Blob([vcfData], 'text/vcard');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'contact.vcf')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  static Future<void> _connectToWifi(String config) async {
    try {
      if (Platform.isAndroid) {
        final parts = config.split(';');
        final ssid = parts.firstWhere((p) => p.startsWith('S=')).substring(2);

        final intent = AndroidIntent(
          action: 'android.settings.WIFI_SETTINGS',
        );
        await intent.launch();
      } else {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Please connect to network manually: $config'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error connecting to WiFi: $e');
    }
  }

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class QRDataType {
  final String name;
  final IconData icon;
  final String hint;
  final String? Function(String) validator;
  final String Function(String, bool) formatter;
  final Future<void> Function(BuildContext, String)? action;

  QRDataType({
    required this.name,
    required this.icon,
    required this.hint,
    required this.validator,
    required this.formatter,
    this.action,
  });

  bool get hasAction => action != null;
}
