import 'file_exporter_stub.dart'
    if (dart.library.html) 'file_exporter_web.dart' as impl;

/// Cross-platform file exporter supporting Web (browser direct download)
/// and Native mobile/desktop (Share sheet via temporary file).
class FileExporter {
  /// Exports text content (such as CSV or JSON) to a downloadable/shareable file.
  static Future<void> exportString({
    required String content,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    await impl.exportString(
      content: content,
      fileName: fileName,
      mimeType: mimeType,
      subject: subject,
    );
  }

  /// Exports binary bytes (such as PDF or images) to a downloadable/shareable file.
  static Future<void> exportBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    await impl.exportBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      subject: subject,
    );
  }
}
