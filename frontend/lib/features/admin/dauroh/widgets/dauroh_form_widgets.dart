import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DaurohField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool optional;
  final TextInputType? keyboardType;

  const DaurohField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.optional = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: optional ? null : (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixText: optional ? 'Opsional' : null,
        suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.grey400),
      ),
    );
  }
}

class DaurohDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const DaurohDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class DaurohMultiSelect<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final Set<T> selectedIds;
  final String Function(T) labelFn;
  final ValueChanged<T> onChanged;

  const DaurohMultiSelect({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedIds,
    required this.labelFn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${selectedIds.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Memuat data...', style: TextStyle(color: AppTheme.grey500, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: items.map((item) {
                final isSelected = selectedIds.contains(item);
                return FilterChip(
                  label: Text(labelFn(item), style: TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => onChanged(item),
                  selectedColor: AppTheme.primaryLight,
                  checkmarkColor: AppTheme.primary,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
