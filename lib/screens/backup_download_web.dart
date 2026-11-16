// dart:html keeps this web download helper compatible with the project's
// minimum Dart 2.19 SDK. The file is selected only by a web conditional import.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

void downloadBackup(String fileName, Uint8List bytes) {
  final blob = html.Blob([bytes], 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..click();
  anchor.remove();
  Timer(const Duration(seconds: 1), () => html.Url.revokeObjectUrl(url));
}
