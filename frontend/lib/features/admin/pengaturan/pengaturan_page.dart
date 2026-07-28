import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/network/api_client.dart';
import '../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/models/user_model.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.security_outlined), text: 'Hak Akses'),
            Tab(icon: Icon(Icons.history), text: 'Log'),
            Tab(icon: Icon(Icons.backup_outlined), text: 'Backup'),
            Tab(icon: Icon(Icons.restore_outlined), text: 'Restore'),
            Tab(icon: Icon(Icons.school_outlined), text: 'Profil'),
            Tab(icon: Icon(Icons.login_outlined), text: 'Tampilan'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _HakAksesTab(),
        _LogTab(),
        _BackupTab(),
        _RestoreTab(),
        _ProfilTab(),
        _TampilanLoginTab(),
      ]),
    );
  }
}

// ── Hak Akses Tab ──
class _HakAksesTab extends StatefulWidget {
  @override
  State<_HakAksesTab> createState() => _HakAksesTabState();
}

const _roleIcons = {
  'admin': Icons.shield_outlined,
  'kepala_sekolah': Icons.school_outlined,
  'wakil_kurikulum': Icons.auto_stories_outlined,
  'guru_mapel_wali_kelas': Icons.people_outlined,
  'guru_bk': Icons.psychology_outlined,
};

class _HakAksesTabState extends State<_HakAksesTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getHakAkses();
      if (mounted) setState(() { _items = res.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _add() {
    String? _role, _modul, _aksi = 'view';
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah Hak Akses'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              decoration: _inpDeco('Role', Icons.badge_outlined),
              items: _roleIcons.entries.map((e) => DropdownMenuItem(value: e.key,
                child: Row(children: [Icon(e.value, size: 18), const SizedBox(width: 8), Text(UserModel.roleDisplayName(e.key))]),
              )).toList(),
              onChanged: (v) { _role = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: _inpDeco('Modul', Icons.widgets_outlined),
              items: ['dashboard', 'master_data', 'penjadwalan', 'absensi', 'nilai', 'rapor', 'pengaduan', 'konseling', 'bakat_minat', 'kenaikan_kelas', 'alumni', 'users', 'pengaturan', 'laporan']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) { _modul = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: _inpDeco('Aksi', Icons.flash_on_outlined),
              items: const ['view', 'create', 'edit', 'delete', 'validate']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { _aksi = v; setD(() {}); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await AdminService.addHakAkses({'role': _role, 'modul': _modul, 'aksi': _aksi});
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showConfirmDialog(context, title: 'Hapus', message: 'Yakin hapus hak akses ini?');
    if (!ok) return;
    try { await AdminService.deleteHakAkses(id); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _items.isEmpty
            ? Center(child: Text('Belum ada hak akses.', style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final role = item['role']?.toString() ?? '';
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_roleIcons[role] ?? Icons.person_outline, size: 20, color: Colors.blue[700]),
                      ),
                      title: Text(UserModel.roleDisplayName(role), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Modul: ${item['modul']}  ·  Aksi: ${item['aksi']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _delete(item['id'] as int)),
                    ),
                  );
                },
              )),
      ]),
    );
  }
}

// ── Log Tab ──
class _LogTab extends StatefulWidget {
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getLogAktivitas(page: _page);
      if (mounted) setState(() {
        _logs = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
        _loading = false;
      });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  IconData _aksiIcon(String? aksi) {
    switch (aksi) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.remove_circle_outline;
      case 'login': return Icons.login;
      case 'backup': return Icons.backup;
      case 'restore': return Icons.restore;
      default: return Icons.history;
    }
  }

  Color _aksiColor(String? aksi) {
    switch (aksi) {
      case 'create': return Colors.green;
      case 'update': return Colors.orange;
      case 'delete': return Colors.red;
      case 'login': return Colors.blue;
      case 'backup': return Colors.purple;
      case 'restore': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Expanded(child: _logs.isEmpty
            ? Center(child: Text('Belum ada log.', style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  final log = _logs[i];
                  final aksi = log['aksi']?.toString();
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _aksiColor(aksi).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_aksiIcon(aksi), size: 20, color: _aksiColor(aksi)),
                      ),
                      title: Row(children: [
                        Text(log['username']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _aksiColor(aksi).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(aksi ?? '-', style: TextStyle(fontSize: 11, color: _aksiColor(aksi), fontWeight: FontWeight.w500)),
                        ),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 2),
                        Text('${log['modul'] ?? '-'} — ${log['detail'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text(log['created_at']?.toString() ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      ]),
                    ),
                  );
                },
              )),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text('$_page / $_totalPages', style: const TextStyle(fontSize: 13)),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page < _totalPages ? () { _page++; _load(); } : null),
        ]),
      ]),
    );
  }
}

// ── Backup Tab ──
class _BackupTab extends StatefulWidget {
  @override
  State<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<_BackupTab> {
  bool _loading = false;
  String? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    try {
      final res = await AdminService.getLogAktivitas(page: 1, perPage: 1);
      final items = res['items'] as List;
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        if (m['aksi'] == 'backup') {
          _lastBackup = m['created_at']?.toString();
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _doBackup() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('/admin/backup');
      final data = res['data'] as Map<String, dynamic>;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final blob = html.Blob([jsonStr], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final now = DateTime.now();
      final filename = 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      _lastBackup = now.toIso8601String().replaceAll('T', ' ').split('.')[0];
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup berhasil: $filename')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.backup, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              Text('Backup Database', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Download seluruh data ke file JSON.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(_lastBackup != null ? 'Backup terakhir: $_lastBackup' : 'Belum pernah backup',
                      style: TextStyle(fontSize: 13, color: _lastBackup != null ? Colors.grey[700] : Colors.grey[500])),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _doBackup,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: Text(_loading ? 'Memproses...' : 'Download Backup'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Restore Tab ──
class _RestoreTab extends StatefulWidget {
  @override
  State<_RestoreTab> createState() => _RestoreTabState();
}

class _RestoreTabState extends State<_RestoreTab> {
  bool _loading = false;
  String? _fileName;
  int? _fileSize;

  Future<void> _pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
      return;
    }

    setState(() {
      _fileName = result.files.first.name;
      _fileSize = bytes.length;
      _loading = true;
    });

    try {
      final jsonStr = utf8.decode(bytes);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = parsed['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('File backup tidak valid: field "data" tidak ditemukan');
      }
      await AdminService.restore({'data': data});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore berhasil!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.restore, size: 48, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              Text('Restore Database', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Pilih file backup JSON untuk mengembalikan data.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _fileName != null ? Colors.orange.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _fileName != null ? Colors.orange.shade200 : Colors.grey.shade200),
                ),
                child: _fileName != null
                    ? Row(children: [
                        Icon(Icons.insert_drive_file, size: 20, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_fileName!, style: TextStyle(fontSize: 13, color: Colors.orange[900])),
                        ),
                        Text(_fmtSize(_fileSize!), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ])
                    : Row(children: [
                        Icon(Icons.folder_open, size: 20, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text('Belum ada file dipilih', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _pickAndRestore,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file),
                  label: Text(_loading ? 'Merestore...' : 'Pilih & Restore File'),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.warning_amber_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text('Akan menimpa data yang sudah ada', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Profil Sekolah Tab ──
class _ProfilTab extends StatefulWidget {
  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _telpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getProfil();
      _namaCtrl.text = data['nama']?.toString() ?? '';
      _alamatCtrl.text = data['alamat']?.toString() ?? '';
      _telpCtrl.text = data['telepon']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await AdminService.updateProfil({
        'nama': _namaCtrl.text,
        'alamat': _alamatCtrl.text,
        'telepon': _telpCtrl.text,
        'email': _emailCtrl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sekolah tersimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose(); _alamatCtrl.dispose(); _telpCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FormCard(title: 'Profil Sekolah', icon: Icons.school_outlined, children: [
            _ModernField(controller: _namaCtrl, label: 'Nama Sekolah', icon: Icons.badge_outlined),
            const SizedBox(height: 16),
            TextField(controller: _alamatCtrl, maxLines: 3,
              decoration: _inpDeco('Alamat', Icons.location_on_outlined)),
            const SizedBox(height: 16),
            _ModernField(controller: _telpCtrl, label: 'Telepon', icon: Icons.phone_outlined),
            const SizedBox(height: 16),
            _ModernField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined),
            const SizedBox(height: 20),
            Row(children: [
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan Profil')),
              const SizedBox(width: 16),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
            ]),
          ]),
        ]),
      ),
    );
  }
}

// ── Tampilan Login Tab ──
class _TampilanLoginTab extends StatefulWidget {
  @override
  State<_TampilanLoginTab> createState() => _TampilanLoginTabState();
}

class _TampilanLoginTabState extends State<_TampilanLoginTab> {
  final _heroTitleCtrl = TextEditingController();
  final _heroSubtitleCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _bgUrlCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await AdminService.getPengaturanTampilan();
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        if (m['key'] == 'hero_title') _heroTitleCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'hero_subtitle') _heroSubtitleCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'logo_url') _logoUrlCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'background_url') _bgUrlCtrl.text = m['value'] as String? ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await AdminService.updatePengaturanTampilan({
        'hero_title': _heroTitleCtrl.text,
        'hero_subtitle': _heroSubtitleCtrl.text,
        'logo_url': _logoUrlCtrl.text,
        'background_url': _bgUrlCtrl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tampilan login tersimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  void dispose() {
    _heroTitleCtrl.dispose(); _heroSubtitleCtrl.dispose();
    _logoUrlCtrl.dispose(); _bgUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FormCard(title: 'Tampilan Halaman Login', icon: Icons.login_outlined, children: [
            _ModernField(controller: _heroTitleCtrl, label: 'Judul Hero', icon: Icons.title),
            const SizedBox(height: 16),
            TextField(controller: _heroSubtitleCtrl, maxLines: 3,
              decoration: _inpDeco('Subtitle Hero', Icons.description_outlined)),
            const SizedBox(height: 16),
            _ModernField(controller: _logoUrlCtrl, label: 'URL Logo', icon: Icons.image_outlined, hint: 'https://...'),
            const SizedBox(height: 16),
            _ModernField(controller: _bgUrlCtrl, label: 'URL Background', icon: Icons.wallpaper_outlined, hint: 'https://...'),
            const SizedBox(height: 20),
            Row(children: [
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan')),
              const SizedBox(width: 16),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
            ]),
          ]),
          const SizedBox(height: 16),
          Text('Pratinjau', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFFFDD835)]),
              borderRadius: BorderRadius.circular(12),
              image: _bgUrlCtrl.text.isNotEmpty
                  ? DecorationImage(image: NetworkImage(_bgUrlCtrl.text), fit: BoxFit.cover, opacity: 0.3)
                  : null,
            ),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _logoUrlCtrl.text.isNotEmpty
                    ? Image.network(_logoUrlCtrl.text, width: 40, height: 40, color: Colors.white)
                    : const Icon(Icons.school, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(_heroTitleCtrl.text.isNotEmpty ? _heroTitleCtrl.text : 'Judul',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_heroSubtitleCtrl.text.isNotEmpty ? _heroSubtitleCtrl.text : 'Subtitle',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

InputDecoration _inpDeco(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
  );
}

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _FormCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  const _ModernField({required this.controller, required this.label, required this.icon, this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }
}
