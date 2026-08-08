import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class BulkUploadConfig {
  final String title;
  final double dialogWidth;
  final String Function(Map<String, dynamic> row) primaryLabel;
  final String Function(Map<String, dynamic> row)? secondaryLabel;
  final String Function(Map<String, dynamic> row)? tertiaryLabel;
  final List<String> saveFields;
  final String bulkEndpoint;
  final VoidCallback onSaved;

  const BulkUploadConfig({
    required this.title,
    this.dialogWidth = 700,
    required this.primaryLabel,
    this.secondaryLabel,
    this.tertiaryLabel,
    required this.saveFields,
    required this.bulkEndpoint,
    required this.onSaved,
  });
}

class BulkUploadDialog extends StatelessWidget {
  final BulkUploadConfig config;
  final List<Map<String, dynamic>> rows;

  const BulkUploadDialog({
    super.key,
    required this.config,
    required this.rows,
  });

  static Future<void> show({
    required BuildContext context,
    required BulkUploadConfig config,
    required List<Map<String, dynamic>> rows,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BulkUploadDialog(config: config, rows: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount = rows.where((r) => r['valid'] == true).length;
    final errorCount = rows.length - validCount;
    final hasErrors = errorCount > 0;

    return AlertDialog(
      title: Text('${config.title} (${rows.length} baris)'),
      content: SizedBox(
        width: config.dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$validCount valid, $errorCount error',
                style: TextStyle(
                  color: hasErrors ? AppTheme.error : AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((r) => _buildRow(r)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        if (validCount > 0)
          FilledButton(
            onPressed: () => _onSave(context),
            child: Text('Simpan $validCount Data'),
          ),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> r) {
    final isValid = r['valid'] == true;
    final isUpdate = r['is_update'] == true;
    final errors = r['errors'] is List ? (r['errors'] as List) : [];

    // Waya berbeda: biru untuk insert, oranye untuk update, merah untuk error
    Color bgColor;
    Color borderColor;
    if (!isValid) {
      bgColor = AppTheme.error.withValues(alpha: 0.05);
      borderColor = AppTheme.error.withValues(alpha: 0.2);
    } else if (isUpdate) {
      bgColor = Colors.orange.withValues(alpha: 0.05);
      borderColor = Colors.orange.withValues(alpha: 0.2);
    } else {
      bgColor = AppTheme.primary.withValues(alpha: 0.05);
      borderColor = AppTheme.primary.withValues(alpha: 0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${r['row']}',
              style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.primaryLabel(r),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (config.secondaryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    config.secondaryLabel!(r),
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                  ),
                ],
                if (config.tertiaryLabel != null)
                  Text(
                    config.tertiaryLabel!(r),
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                  ),
                if (errors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      errors.join('; '),
                      style: const TextStyle(fontSize: 12, color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
    final validRows = rows
        .where((r) => r['valid'] == true)
        .map((r) => {
              for (final field in config.saveFields) field: r[field],
            })
        .toList();

    try {
      final res = await ApiClient.post(config.bulkEndpoint, body: {'data': validRows});
      final result = res['data'] as Map<String, dynamic>;
      final inserted = result['inserted'] ?? 0;
      final updated = result['updated'] ?? 0;
      final errors = (result['errors'] as List?) ?? [];
      if (!context.mounted) return;

      Navigator.pop(context);

      final parts = <String>[];
      if (inserted > 0) parts.add('$inserted ditambahkan');
      if (updated > 0) parts.add('$updated diupdate');
      if (errors.isNotEmpty) parts.add('${errors.length} gagal');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          parts.isEmpty ? 'Tidak ada data diproses' : 'Berhasil: ${parts.join(', ')}',
        ),
      ));
      config.onSaved();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e')),
      );
    }
  }
}
