// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

Future<void> exportString({
  required String content,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}

Future<void> exportBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}
