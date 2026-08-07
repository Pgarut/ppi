import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

class MasterDataTableColumn {
  final String key;
  final String label;
  final int flex;
  final String Function(dynamic value, Map<String, dynamic> row)? displayFn;

  const MasterDataTableColumn({
    required this.key,
    required this.label,
    this.flex = 1,
    this.displayFn,
  });
}

class MasterDataTable extends StatelessWidget {
  final List<MasterDataTableColumn> columns;
  final List<Map<String, dynamic>> data;
  final bool showActions;
  final void Function(Map<String, dynamic> row)? onEdit;
  final void Function(Map<String, dynamic> row)? onDelete;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const MasterDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.showActions = true,
    this.onEdit,
    this.onDelete,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: AppTheme.error)));
    }
    if (data.isEmpty) {
      return const EmptyState(icon: Icons.inbox_outlined, message: 'Belum ada data.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
        if (totalPages > 1) _buildPagination(),
      ]),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionsWidth = showActions ? 80.0 : 0.0;
        final totalFlex = columns.fold<int>(0, (sum, c) => sum + c.flex);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            border: Border(bottom: BorderSide(color: AppTheme.grey200)),
          ),
          child: Row(children: [
            ...columns.map((col) {
              final colWidth = (constraints.maxWidth - actionsWidth) * col.flex / totalFlex;
              return SizedBox(
                width: colWidth,
                child: Text(
                  col.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700),
                ),
              );
            }),
            if (showActions)
              const SizedBox(
                width: 80,
                child: Text('Aksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700)),
              ),
          ]),
        );
      },
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionsWidth = showActions ? 80.0 : 0.0;
        final totalFlex = columns.fold<int>(0, (sum, c) => sum + c.flex);

        return ListView.separated(
          itemCount: data.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final row = data[i];
            return Container(
              color: i.isEven ? null : AppTheme.grey50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(children: [
                ...columns.map((col) {
                  final val = col.displayFn != null
                      ? col.displayFn!(row[col.key], row)
                      : (row[col.key]?.toString() ?? '-');
                  final colWidth = (constraints.maxWidth - actionsWidth) * col.flex / totalFlex;
                  return SizedBox(
                    width: colWidth,
                    child: Text(val, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                  );
                }),
                if (showActions)
                  SizedBox(
                    width: actionsWidth,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.grey500),
                          onPressed: () => onEdit!(row),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      const SizedBox(width: 4),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                          onPressed: () => onDelete!(row),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                    ]),
                  ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
        border: Border(top: BorderSide(color: AppTheme.grey200)),
      ),
      child: PaginationRow(
        currentPage: currentPage,
        totalPages: totalPages,
        onPrevious: onPrevious,
        onNext: onNext,
      ),
    );
  }
}
