import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DaurohTableColumn {
  final String key;
  final String label;
  final double width;

  const DaurohTableColumn({
    required this.key,
    required this.label,
    this.width = 150,
  });
}

class DaurohTable extends StatelessWidget {
  final List<DaurohTableColumn> columns;
  final List<Map<String, dynamic>> data;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final void Function(Map<String, dynamic> row)? onEdit;
  final void Function(Map<String, dynamic> row)? onDelete;
  final String Function(String key, dynamic value, Map<String, dynamic> row)? displayFn;

  const DaurohTable({
    super.key,
    required this.columns,
    required this.data,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevious,
    this.onNext,
    this.onEdit,
    this.onDelete,
    this.displayFn,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: AppTheme.error, fontSize: 14)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.grey300),
            SizedBox(height: 12),
            Text('Belum ada data', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
        if (totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: AppTheme.grey200)),
      ),
      child: Row(
        children: [
          ...columns.map((col) => Expanded(
            flex: (col.width / 10).toInt(),
            child: Text(
              col.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700),
            ),
          )),
          const SizedBox(
            width: 80,
            child: Text(
              'Aksi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final row = data[i];
        return Container(
          color: i.isEven ? null : AppTheme.grey50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ...columns.map((col) {
                final val = row[col.key];
                final display = displayFn != null
                    ? displayFn!(col.key, val, row)
                    : (val?.toString() ?? '-');
                return Expanded(
                  flex: (col.width / 10).toInt(),
                  child: Text(
                    display,
                    style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
                    maxLines: 2,
                  ),
                );
              }),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.grey500),
                        onPressed: () => onEdit!(row),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 4),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                        onPressed: () => onDelete!(row),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPrevious,
            color: AppTheme.grey600,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onNext,
            color: AppTheme.grey600,
          ),
        ],
      ),
    );
  }
}
