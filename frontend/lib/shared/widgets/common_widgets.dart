import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE - Consistent empty/error state widget
// ═══════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.grey300),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppTheme.grey500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STATUS BADGE - Colored status indicator
// ═══════════════════════════════════════════════════════════
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Common status badge presets
class AttendanceStatus {
  static StatusBadge hadir() => const StatusBadge(label: 'Hadir', color: AppTheme.primary);
  static StatusBadge izin() => const StatusBadge(label: 'Izin', color: AppTheme.orange);
  static StatusBadge sakit() => const StatusBadge(label: 'Sakit', color: AppTheme.blue);
  static StatusBadge alpa() => const StatusBadge(label: 'Alpa', color: AppTheme.error);

  static StatusBadge fromString(String status) {
    switch (status) {
      case 'hadir': return hadir();
      case 'izin': return izin();
      case 'sakit': return sakit();
      case 'alpa': return alpa();
      default: return StatusBadge(label: status, color: AppTheme.grey400);
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case 'hadir': return AppTheme.primary;
      case 'izin': return AppTheme.orange;
      case 'sakit': return AppTheme.blue;
      case 'alpa': return AppTheme.error;
      default: return AppTheme.grey400;
    }
  }
}

class GradeStatus {
  static StatusBadge validated() => const StatusBadge(label: 'Tervalidasi', color: AppTheme.primary);
  static StatusBadge draft() => const StatusBadge(label: 'Draft', color: AppTheme.orange);
  static StatusBadge sent() => const StatusBadge(label: 'Terkirim', color: AppTheme.blue);

  static StatusBadge fromString(String status) {
    switch (status) {
      case 'divalidasi': case 'tervalidasi': return validated();
      case 'draft': return draft();
      case 'terkirim': return sent();
      default: return StatusBadge(label: status, color: AppTheme.grey400);
    }
  }
}

class AuditAction {
  static Color colorFor(String aksi) {
    switch (aksi) {
      case 'create': return AppTheme.primary;
      case 'update': return AppTheme.orange;
      case 'delete': return AppTheme.error;
      case 'cetak': case 'print': return AppTheme.blue;
      case 'login': return AppTheme.indigo;
      case 'backup': return AppTheme.teal;
      case 'restore': return AppTheme.secondary;
      default: return AppTheme.grey400;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  SECTION TITLE - Consistent section header
// ═══════════════════════════════════════════════════════════
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.grey800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER CARD - Consistent filter container
// ═══════════════════════════════════════════════════════════
class FilterCard extends StatelessWidget {
  final List<Widget> children;
  final Widget? trailing;

  const FilterCard({
    super.key,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...children,
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  DATA CARD - Consistent data container
// ═══════════════════════════════════════════════════════════
class DataCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? header;

  const DataCard({
    super.key,
    required this.child,
    this.padding,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: header!,
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MODERN DATATABLE CARD
// ═══════════════════════════════════════════════════════════
class ModernTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const ModernTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppTheme.grey700,
          ),
          dataTextStyle: const TextStyle(
            fontSize: 13,
            color: AppTheme.grey700,
          ),
          columnSpacing: 24,
          horizontalMargin: 20,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PAGINATION ROW
// ═══════════════════════════════════════════════════════════
class PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationRow({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  APP INPUT DECORATION - Consistent InputDecoration factory
// ═══════════════════════════════════════════════════════════
class AppInputDecoration {
  /// Standard input decoration for forms.
  ///
  /// [style] defaults to [InputDecorationStyle.outlined].
  static InputDecoration standard(
    String label,
    IconData icon, {
    bool optional = false,
    String? hint,
    InputDecorationStyle style = InputDecorationStyle.outlined,
    Color? fillColor,
  }) {
    switch (style) {
      case InputDecorationStyle.login:
        return _loginStyle(label, icon, fillColor: fillColor);
      case InputDecorationStyle.filled:
        return _filledStyle(label, icon, optional: optional, hint: hint, fillColor: fillColor);
      case InputDecorationStyle.outlined:
        return _outlinedStyle(label, icon, optional: optional, hint: hint, fillColor: fillColor);
    }
  }

  static InputDecoration _outlinedStyle(
    String label,
    IconData icon, {
    bool optional = false,
    String? hint,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint ?? (optional ? 'Opsional' : null),
      prefixIcon: Icon(icon, size: 20),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static InputDecoration _filledStyle(
    String label,
    IconData icon, {
    bool optional = false,
    String? hint,
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint ?? (optional ? 'Opsional' : null),
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  static InputDecoration _loginStyle(
    String label,
    IconData icon, {
    Color? fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fillColor ?? Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    );
  }
}

enum InputDecorationStyle { outlined, filled, login }

// ═══════════════════════════════════════════════════════════
//  LOAD MORE BUTTON - Reusable pagination button
// ═══════════════════════════════════════════════════════════
class LoadMoreButton extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onLoadMore;
  final bool isLoading;

  const LoadMoreButton({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onLoadMore,
    this.isLoading = false,
  });

  bool get hasMore => currentPage < totalPages;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              )
            : OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('Muat lebih banyak'),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STAT CHIP
// ═══════════════════════════════════════════════════════════
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
