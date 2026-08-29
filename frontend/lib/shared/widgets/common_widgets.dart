import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
//  SAFE NETWORK IMAGE - Menghindari ImageCodecException
//  Mencegah error "Failed to detect image file format" saat server
//  mengembalikan konten HTML (mis. logo_url/background_url salah)
//  atau status non-2xx. Memvalidasi magic bytes sebelum decode.
// ═══════════════════════════════════════════════════════════
class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final Widget? errorWidget;
  final Widget? placeholder;
  final Alignment alignment;

  const SafeNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.errorWidget,
    this.placeholder,
    this.alignment = Alignment.center,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  Uint8List? _bytes;
  String? _error;

  static bool _looksLikeImage(List<int> b) {
    if (b.length < 12) return false;
    // PNG
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return true;
    // JPEG
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true;
    // GIF
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return true;
    // BMP
    if (b[0] == 0x42 && b[1] == 0x4D) return true;
    // WebP (RIFF....WEBP)
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return true;
    }
    // SVG (teks) - biarkan Flutter menanganinya; bukan gambar raster utama
    return false;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() { _bytes = null; _error = null; });
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url.isEmpty) {
      setState(() => _error = 'empty');
      return;
    }
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        setState(() => _error = 'scheme');
        return;
      }
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        setState(() => _error = 'http ${res.statusCode}');
        return;
      }
      final body = res.bodyBytes;
      if (!_looksLikeImage(body)) {
        setState(() => _error = 'not-image');
        return;
      }
      if (mounted) setState(() => _bytes = body);
    } catch (_) {
      if (mounted) setState(() => _error = 'network');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ??
          const Icon(Icons.broken_image_outlined, color: AppTheme.grey300);
    }
    if (_bytes == null) {
      return widget.placeholder ??
          const SizedBox.shrink();
    }
    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      color: widget.color,
      alignment: widget.alignment,
      errorBuilder: (_, __, ___) =>
          widget.errorWidget ??
          const Icon(Icons.broken_image_outlined, color: AppTheme.grey300),
    );
  }
}

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
      case 'alpa': case 'alpha': return alpa();
      default: return StatusBadge(label: status, color: AppTheme.grey400);
    }
  }

  static Color colorFor(String status) {
    switch (status) {
      case 'hadir': return AppTheme.primary;
      case 'izin': return AppTheme.orange;
      case 'sakit': return AppTheme.blue;
      case 'alpa': case 'alpha': return AppTheme.error;
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
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
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
