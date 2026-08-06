import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_form_widgets.dart';

class MusyrifahFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback? onSaved;

  const MusyrifahFormPage({super.key, this.editData, this.onSaved});

  @override
  State<MusyrifahFormPage> createState() => _MusyrifahFormPageState();
}

class _MusyrifahFormPageState extends State<MusyrifahFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nipmusCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _gelarCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _jenisKelamin = 'L';
  String _statusPendidikan = 'selesai';
  bool _isAktif = true;
  bool _saving = false;
  bool _obscurePassword = true;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _nipmusCtrl.text = d['nipmus']?.toString() ?? '';
      _namaCtrl.text = d['nama']?.toString() ?? '';
      _gelarCtrl.text = d['gelar']?.toString() ?? '';
      _usernameCtrl.text = d['username']?.toString() ?? '';
      _jenisKelamin = d['jenis_kelamin']?.toString() ?? 'L';
      _statusPendidikan = d['status_pendidikan']?.toString() ?? 'selesai';
      _isAktif = d['is_aktif'] == 1;
    }
  }

  @override
  void dispose() {
    _nipmusCtrl.dispose();
    _namaCtrl.dispose();
    _gelarCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = <String, dynamic>{
        'nipmus': _nipmusCtrl.text,
        'nama': _namaCtrl.text,
        'jenis_kelamin': _jenisKelamin,
        'status_pendidikan': _statusPendidikan,
        'gelar': _gelarCtrl.text.isNotEmpty ? _gelarCtrl.text : null,
        'username': _usernameCtrl.text,
        'is_aktif': _isAktif ? 1 : 0,
      };

      if (!_isEdit || _passwordCtrl.text.isNotEmpty) {
        body['password'] = _passwordCtrl.text;
      }

      if (_isEdit) {
        await DaurohService.updateMusyrifah(widget.editData!['id'] as int, body);
      } else {
        await DaurohService.createMusyrifah(body);
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
      title: Text(_isEdit ? 'Edit Musyrifah' : 'Tambah Musyrifah'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DaurohField(
                  controller: _nipmusCtrl,
                  label: 'NIPMUS',
                  icon: Icons.badge_outlined,
                  hint: 'Nomor induk musyrifah',
                ),
                const SizedBox(height: 16),
                DaurohField(
                  controller: _namaCtrl,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                DaurohDropdown<String>(
                  value: _jenisKelamin,
                  label: 'Jenis Kelamin',
                  icon: Icons.wc_outlined,
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (v) => setState(() => _jenisKelamin = v ?? 'L'),
                ),
                const SizedBox(height: 16),
                DaurohDropdown<String>(
                  value: _statusPendidikan,
                  label: 'Status Pendidikan',
                  icon: Icons.school_outlined,
                  items: const [
                    DropdownMenuItem(value: 'selesai', child: Text('Selesai (Sarjana)')),
                    DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                  ],
                  onChanged: (v) => setState(() => _statusPendidikan = v ?? 'selesai'),
                ),
                const SizedBox(height: 16),
                DaurohField(
                  controller: _gelarCtrl,
                  label: 'Gelar',
                  icon: Icons.emoji_events_outlined,
                  optional: true,
                  hint: 'Contoh: S.Pd.I',
                ),
                const SizedBox(height: 16),
                DaurohField(
                  controller: _usernameCtrl,
                  label: 'Username',
                  icon: Icons.account_circle_outlined,
                  hint: 'Untuk login musyrifah',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  validator: _isEdit
                      ? null
                      : (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Password (kosongkan jika tidak ubah)' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _isAktif ? 'Musyrifah aktif' : 'Musyrifah tidak aktif',
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
