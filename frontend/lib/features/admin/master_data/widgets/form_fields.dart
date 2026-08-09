import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';

class FormRow extends StatelessWidget {
  final List<Widget> children;
  const FormRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool optional;
  final TextInputType? keyboardType;

  const ModernField({
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

class ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const ModernDropdown({
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

class ModernPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final String? suffixText;

  const ModernPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
    this.validator,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.grey400),
      ),
    );
  }
}

class ModernCheckboxList<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final Set<T> selectedIds;
  final String Function(T) labelFn;
  final ValueChanged<T> onChanged;

  const ModernCheckboxList({
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
    return DataCard(
      header: Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (items.isEmpty)
          const Text('Memuat data...', style: TextStyle(color: AppTheme.grey500))
        else
          ...items.map((item) => CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(labelFn(item), style: const TextStyle(fontSize: 14)),
            value: selectedIds.contains(item),
            onChanged: (_) => onChanged(item),
          )),
      ]),
    );
  }
}

class ModernCheckboxGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<MapEntry<String, String>> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onChanged;

  const ModernCheckboxGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey600)),
        const SizedBox(height: 4),
        ...options.map((opt) => CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          title: Text(opt.value, style: const TextStyle(fontSize: 14)),
          value: selectedValues.contains(opt.key),
          onChanged: (_) => onChanged(opt.key),
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  MULTI-SELECT DIALOG WITH SEARCH
// ═══════════════════════════════════════════════════════════
class MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final Set<T> selectedIds;
  final String Function(T) labelFn;
  final double dialogWidth;

  const MultiSelectDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedIds,
    required this.labelFn,
    this.dialogWidth = 400,
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

/// Top-level function to show MultiSelectDialog
Future<Set<T>?> showMultiSelectDialog<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<T> items,
  required Set<T> selectedIds,
  required String Function(T) labelFn,
  double dialogWidth = 400,
}) {
  return showDialog<Set<T>>(
    context: context,
    builder: (_) => MultiSelectDialog<T>(
      title: title,
      icon: icon,
      items: items,
      selectedIds: Set.from(selectedIds),
      labelFn: labelFn,
      dialogWidth: dialogWidth,
    ),
  );
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late Set<T> _tempSelected;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return widget.labelFn(item).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Icon(widget.icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_tempSelected.length}/${widget.items.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
          ),
        ),
      ]),
      content: SizedBox(
        width: widget.dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppTheme.grey50,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _filteredItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tidak ditemukan', style: TextStyle(color: AppTheme.grey400)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (_, i) {
                        final item = _filteredItems[i];
                        final isSelected = _tempSelected.contains(item);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _tempSelected.remove(item);
                              } else {
                                _tempSelected.add(item);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryLight : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                size: 20,
                                color: isSelected ? AppTheme.primary : AppTheme.grey400,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.labelFn(item),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryDark : AppTheme.grey700,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _tempSelected),
          child: Text('Pilih (${_tempSelected.length})'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SELECTABLE CHIP GROUP - Shows selected items as chips
// ═══════════════════════════════════════════════════════════
class SelectableChipGroup<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> allItems;
  final Set<T> selectedIds;
  final String Function(T) labelFn;
  final VoidCallback onTap;
  final Color? chipColor;

  const SelectableChipGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.allItems,
    required this.selectedIds,
    required this.labelFn,
    required this.onTap,
    this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = chipColor ?? AppTheme.primary;
    return DataCard(
      header: Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        if (selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${selectedIds.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedIds.isEmpty)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.grey200, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 32, color: AppTheme.grey400),
                    const SizedBox(height: 8),
                    Text('Tap untuk memilih $title', style: const TextStyle(fontSize: 13, color: AppTheme.grey500)),
                  ],
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...selectedIds.map((id) {
                  final item = allItems.firstWhere(
                    (i) => i == id,
                    orElse: () => null as T,
                  );
                  if (item == null) return const SizedBox.shrink();
                  return Chip(
                    label: Text(labelFn(item), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      onTap();
                    },
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                    labelStyle: TextStyle(color: color),
                    deleteIconColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.grey100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.grey300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: AppTheme.grey600),
                        SizedBox(width: 4),
                        Text('Ubah', style: TextStyle(fontSize: 12, color: AppTheme.grey600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ModernDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final BuildContext context;

  const ModernDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
        );
        if (date != null) {
          controller.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}
