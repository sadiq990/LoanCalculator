import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportString({
  required String content,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: subject ?? fileName,
  );
}

Future<void> exportBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: subject ?? fileName,
  );
}
