import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_form_widgets.dart';

class ProgramFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback? onSaved;

  const ProgramFormPage({super.key, this.editData, this.onSaved});

  @override
  State<ProgramFormPage> createState() => _ProgramFormPageState();
}

class _ProgramFormPageState extends State<ProgramFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  String _jenisProgram = 'kelas';
  String _jenisDauroh = 'hafalan';
  bool _isAktif = true;
  bool _saving = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _namaCtrl.text = d['nama_program']?.toString() ?? '';
      _keteranganCtrl.text = d['keterangan']?.toString() ?? '';
      _jenisProgram = d['jenis_program']?.toString() ?? 'kelas';
      _jenisDauroh = d['jenis_dauroh']?.toString() ?? 'hafalan';
      _isAktif = d['is_aktif'] == 1;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = {
        'nama_program': _namaCtrl.text,
        'jenis_program': _jenisProgram,
        'jenis_dauroh': _jenisDauroh,
        'keterangan': _keteranganCtrl.text.isNotEmpty ? _keteranganCtrl.text : null,
        'is_aktif': _isAktif ? 1 : 0,
      };

      if (_isEdit) {
        await DaurohService.updateProgram(widget.editData!['id'] as int, body);
      } else {
        await DaurohService.createProgram(body);
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Program' : 'Tambah Program'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DaurohField(
                  controller: _namaCtrl,
                  label: 'Nama Program',
                  icon: Icons.book_outlined,
                  hint: 'Contoh: Tahfidz Quran',
                ),
                const SizedBox(height: 16),
                DaurohDropdown<String>(
                  value: _jenisProgram,
                  label: 'Jenis Program',
                  icon: Icons.category_outlined,
                  items: const [
                    DropdownMenuItem(value: 'kelas', child: Text('Kelas (Semua siswa kelas)')),
                    DropdownMenuItem(value: 'khusus', child: Text('Khusus (Pilihan siswa)')),
                  ],
                  onChanged: (v) => setState(() => _jenisProgram = v ?? 'kelas'),
                ),
                const SizedBox(height: 16),
                DaurohDropdown<String>(
                  value: _jenisDauroh,
                  label: 'Jenis Dauroh',
                  icon: Icons.menu_book_outlined,
                  items: const [
                    DropdownMenuItem(value: 'hafalan', child: Text('Hafalan')),
                    DropdownMenuItem(value: 'bacaan', child: Text('Bacaan')),
                  ],
                  onChanged: (v) => setState(() => _jenisDauroh = v ?? 'hafalan'),
                ),
                const SizedBox(height: 16),
                DaurohField(
                  controller: _keteranganCtrl,
                  label: 'Keterangan',
                  icon: Icons.notes_outlined,
                  optional: true,
                  hint: 'Deskripsi program',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _isAktif ? 'Program aktif' : 'Program tidak aktif',
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                  ),
                  value: _isAktif,
                  onChanged: (v) => setState(() => _isAktif = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
