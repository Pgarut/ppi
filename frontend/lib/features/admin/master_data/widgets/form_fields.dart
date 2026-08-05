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
