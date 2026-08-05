import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import '../../../../core/network/api_client.dart';

class MasterDataService {
  static Future<void> downloadTemplate({
    required String entity,
    required String fileName,
  }) async {
    try {
      final res = await ApiClient.get('/admin/$entity/template');
      final data = res['data'] as Map<String, dynamic>;
      final base64Str = data['base64'] as String;
      final bytes = base64Decode(base64Str);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Gagal download template: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> previewUpload({
    required String entity,
    required List<int> fileBytes,
  }) async {
    final base64Str = base64Encode(fileBytes);
    final previewRes = await ApiClient.post('/admin/$entity/preview', body: {
      'file_base64': base64Str,
    });
    final data = previewRes['data'] as Map<String, dynamic>;
    return (data['rows'] as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> bulkSave({
    required String entity,
    required List<Map<String, dynamic>> validRows,
  }) async {
    final res = await ApiClient.post('/admin/$entity/bulk', body: {'data': validRows});
    return res['data'] as Map<String, dynamic>;
  }
}
