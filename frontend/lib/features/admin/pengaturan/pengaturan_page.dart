import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../services/admin_service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/app_utils.dart';
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
    _tabCtrl = TabController(length: 7, vsync: this);
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Hak Akses'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'Log'),
            Tab(icon: Icon(Icons.backup_outlined, size: 18), text: 'Backup'),
            Tab(icon: Icon(Icons.restore_outlined, size: 18), text: 'Restore'),
            Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Profil'),
            Tab(icon: Icon(Icons.login_outlined, size: 18), text: 'Tampilan'),
            Tab(icon: Icon(Icons.key_outlined, size: 18), text: 'API Keys'),
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
        _ApiKeysTab(),
      ]),
    );
  }
}

// ── Hak Akses Tab ──
class _HakAksesTab extends StatefulWidget {
  @override
  State<_HakAksesTab> createState() => _HakAksesTabState();
}

const roleIcons = {
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
    String? role, modul, aksi = 'view';
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah Hak Akses'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Role', Icons.badge_outlined),
              items: roleIcons.entries.map((e) => DropdownMenuItem(value: e.key,
                child: Row(children: [Icon(e.value, size: 18), const SizedBox(width: 8), Text(UserModel.roleDisplayName(e.key))]),
              )).toList(),
              onChanged: (v) { role = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Modul', Icons.widgets_outlined),
              items: ['dashboard', 'master_data', 'penjadwalan', 'absensi', 'nilai', 'rapor', 'pengaduan', 'konseling', 'bakat_minat', 'kenaikan_kelas', 'alumni', 'users', 'pengaturan', 'laporan']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) { modul = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Aksi', Icons.flash_on_outlined),
              items: const ['view', 'create', 'edit', 'delete', 'validate']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { aksi = v; setD(() {}); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await AdminService.addHakAkses({'role': role, 'modul': modul, 'aksi': aksi});
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
    final ok = await AppUtils.confirm(context, title: 'Hapus', message: 'Yakin hapus hak akses ini?');
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
            ? const EmptyState(icon: Icons.security_outlined, message: 'Belum ada hak akses.')
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final role = item['role']?.toString() ?? '';
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(roleIcons[role] ?? Icons.person_outline, size: 20, color: AppTheme.blue),
                      ),
                      title: Text(UserModel.roleDisplayName(role), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Modul: ${item['modul']}  ·  Aksi: ${item['aksi']}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
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
  String? _filterModul;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getLogAktivitas(page: _page);
      if (mounted) { setState(() {
        _logs = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
        _loading = false;
      }); }
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    var result = _logs;
    if (_filterModul != null && _filterModul!.isNotEmpty) {
      result = result.where((l) => l['modul']?.toString() == _filterModul).toList();
    }
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      result = result.where((l) =>
        (l['detail']?.toString() ?? '').toLowerCase().contains(q) ||
        (l['username']?.toString() ?? '').toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  IconData aksiIcon(String? aksi) {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filteredLogs = _filteredLogs;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterModul,
                    hint: const Text('Semua Modul', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: ['absensi', 'guru', 'siswa', 'users', 'backup', 'restore', 'nilai', 'rapor', 'pengaduan', 'master_data', 'pengaturan']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) { setState(() => _filterModul = v); },
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari detail...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: filteredLogs.isEmpty
            ? const EmptyState(icon: Icons.history, message: 'Belum ada log.')
            : ListView.builder(
                itemCount: filteredLogs.length,
                itemBuilder: (_, i) {
                  final log = filteredLogs[i];
                  final aksi = log['aksi']?.toString();
                  final color = AuditAction.colorFor(aksi ?? '');
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(aksiIcon(aksi), size: 20, color: color),
                      ),
                      title: Row(children: [
                        Text(log['username']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        StatusBadge(label: aksi ?? '-', color: color),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 2),
                        Text('${log['modul'] ?? '-'} — ${log['detail'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                        Text(log['created_at']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                      ]),
                    ),
                  );
                },
              )),
        const SizedBox(height: 8),
        PaginationRow(
          currentPage: _page,
          totalPages: _totalPages,
          onPrevious: _page > 1 ? () { _page--; _load(); } : null,
          onNext: _page < _totalPages ? () { _page++; _load(); } : null,
        ),
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
        child: DataCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.backup, size: 48, color: AppTheme.blue),
            ),
            const SizedBox(height: 20),
            Text('Backup Database', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Download seluruh data ke file JSON.', style: TextStyle(color: AppTheme.grey600)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.grey500),
                const SizedBox(width: 8),
                Text(_lastBackup != null ? 'Backup terakhir: $_lastBackup' : 'Belum pernah backup',
                    style: TextStyle(fontSize: 13, color: _lastBackup != null ? AppTheme.grey700 : AppTheme.grey500)),
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
        child: DataCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.restore, size: 48, color: AppTheme.orange),
            ),
            const SizedBox(height: 20),
            Text('Restore Database', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Pilih file backup JSON untuk mengembalikan data.', style: TextStyle(color: AppTheme.grey600)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fileName != null ? AppTheme.orange.withValues(alpha: 0.05) : AppTheme.grey50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fileName != null ? AppTheme.orange.withValues(alpha: 0.3) : AppTheme.grey200),
              ),
              child: _fileName != null
                  ? Row(children: [
                      const Icon(Icons.insert_drive_file, size: 20, color: AppTheme.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_fileName!, style: const TextStyle(fontSize: 13, color: AppTheme.grey700)),
                      ),
                      Text(_fmtSize(_fileSize!), style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                    ])
                  : const Row(children: [
                      Icon(Icons.folder_open, size: 20, color: AppTheme.grey400),
                      SizedBox(width: 8),
                      Text('Belum ada file dipilih', style: TextStyle(fontSize: 13, color: AppTheme.grey500)),
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
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.warning_amber_outlined, size: 14, color: AppTheme.grey400),
              SizedBox(width: 6),
              Text('Akan menimpa data yang sudah ada', style: TextStyle(fontSize: 11, color: AppTheme.grey500)),
            ]),
          ]),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DataCard(
              header: const Row(children: [
                Icon(Icons.school_outlined, size: 20, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Profil Sekolah', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _namaCtrl, decoration: inputDecoration('Nama Sekolah', Icons.badge_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _alamatCtrl, maxLines: 3, decoration: inputDecoration('Alamat', Icons.location_on_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _telpCtrl, decoration: inputDecoration('Telepon', Icons.phone_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _emailCtrl, decoration: inputDecoration('Email', Icons.email_outlined)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan Profil')),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
                  ],
                ),
              ]),
            ),
          ]),
        ),
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DataCard(
              header: const Row(children: [
                Icon(Icons.login_outlined, size: 20, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Tampilan Halaman Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _heroTitleCtrl, decoration: inputDecoration('Judul Hero', Icons.title)),
                const SizedBox(height: 16),
                TextField(controller: _heroSubtitleCtrl, maxLines: 3, decoration: inputDecoration('Subtitle Hero', Icons.description_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _logoUrlCtrl, decoration: inputDecoration('URL Logo', Icons.image_outlined).copyWith(hintText: 'https://...')),
                const SizedBox(height: 16),
                TextField(controller: _bgUrlCtrl, decoration: inputDecoration('URL Background', Icons.wallpaper_outlined).copyWith(hintText: 'https://...')),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan')),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Pratinjau', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.secondary]),
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
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// API Keys Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _ApiKeysTab extends StatefulWidget {
  @override
  State<_ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends State<_ApiKeysTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;
  String? _search;
  String? _statusFilter; // 'aktif', 'nonaktif', null
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getApiKeys(
        page: _page,
        perPage: 20,
        search: _search,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _items = (res['items'] as List).cast<Map<String, dynamic>>();
          _totalPages = res['pagination']?['total_pages'] ?? 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final namaCtrl = TextEditingController();
    String permissions = 'readwrite';
    final rateLimitCtrl = TextEditingController(text: '1000');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Generate API Key Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: inputDecoration('Nama Pihak', Icons.badge_outlined)
                    .copyWith(hintText: 'Contoh: Bank BRI, Toko Maju, Aplikasi Pihak Kedua'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: permissions,
                decoration: inputDecoration('Permission', Icons.lock_outline),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read Only (GET santri, kelas, kenaikan-kelas)')),
                  DropdownMenuItem(value: 'write', child: Text('Write Only (POST pembayaran, notifikasi)')),
                  DropdownMenuItem(value: 'readwrite', child: Text('Read + Write (Semua akses)')),
                ],
                onChanged: (v) { permissions = v!; setD(() {}); },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateLimitCtrl,
                decoration: inputDecoration('Rate Limit (request/hari)', Icons.speed_outlined),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Nama pihak wajib diisi')),
                  );
                  return;
                }
                try {
                  final res = await AdminService.createApiKey({
                    'nama_pihak': namaCtrl.text.trim(),
                    'permissions': permissions,
                    'rate_limit': int.tryParse(rateLimitCtrl.text) ?? 1000,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                  // Show API Key once
                  if (ctx.mounted) {
                    final apiKey = res['api_key'] as String?;
                    if (apiKey != null) {
                      _showApiKeyDialog(apiKey);
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(String apiKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('API Key Dihasilkan')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simpan API Key ini sekarang! Tidak dapat ditampilkan lagi.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey300),
              ),
              child: SelectableText(
                apiKey,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Gunakan header: ', style: TextStyle(fontSize: 12, color: AppTheme.grey600)),
            const Text('X-API-Key: <api_key>', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Sudah Menyimpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final newStatus = !(item['is_aktif'] as bool);
    final nama = item['nama_pihak'] as String;
    try {
      await AdminService.updateApiKey(item['id'] as int, {'is_aktif': newStatus});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nama ${newStatus ? "diaktifkan" : "dinonaktifkan"}')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editPermissions(Map<String, dynamic> item) async {
    String permissions = item['permissions'] as String? ?? 'readwrite';
    final rateLimitCtrl = TextEditingController(text: (item['rate_limit'] ?? 1000).toString());

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Edit: ${item['nama_pihak']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: permissions,
                decoration: inputDecoration('Permission', Icons.lock_outline),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read Only')),
                  DropdownMenuItem(value: 'write', child: Text('Write Only')),
                  DropdownMenuItem(value: 'readwrite', child: Text('Read + Write')),
                ],
                onChanged: (v) { permissions = v!; setD(() {}); },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateLimitCtrl,
                decoration: inputDecoration('Rate Limit (request/hari)', Icons.speed_outlined),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                try {
                  await AdminService.updateApiKey(item['id'] as int, {
                    'permissions': permissions,
                    'rate_limit': int.tryParse(rateLimitCtrl.text) ?? 1000,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus API Key',
      message: 'Yakin hapus API Key "${item['nama_pihak']}"? Tindakan ini tidak dapat dibatalkan.',
    );
    if (!ok) return;
    try {
      await AdminService.deleteApiKey(item['id'] as int);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Header actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.key_outlined, size: 18),
              label: const Text('Generate API Key'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Filter row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    hint: const Text('Semua Status', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Status')),
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                    ],
                    onChanged: (v) { setState(() => _statusFilter = v); _load(); },
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama pihak...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (v) {
                  setState(() => _search = v.trim().isEmpty ? null : v.trim());
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // List
        Expanded(child: _items.isEmpty
            ? const EmptyState(icon: Icons.key_outlined, message: 'Belum ada API Key. Klik "Generate API Key" untuk membuat.')
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final isActive = item['is_aktif'] as bool? ?? false;
                  final permissions = item['permissions'] as String? ?? 'readwrite';
                  final rateLimit = item['rate_limit'] as int? ?? 1000;
                  final lastUsed = item['last_used_at'] as String?;
                  final createdAt = item['created_at'] as String?;

                  Color permColor;
                  String permLabel;
                  switch (permissions) {
                    case 'read':
                      permColor = AppTheme.blue;
                      permLabel = 'Read';
                      break;
                    case 'write':
                      permColor = AppTheme.orange;
                      permLabel = 'Write';
                      break;
                    case 'readwrite':
                      permColor = AppTheme.indigo;
                      permLabel = 'Read + Write';
                      break;
                    default:
                      permColor = AppTheme.grey600;
                      permLabel = permissions;
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isActive ? AppTheme.grey200 : AppTheme.grey100),
                    ),
                    color: isActive ? null : AppTheme.grey50.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.grey300.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.key_outlined,
                                  size: 22,
                                  color: isActive ? AppTheme.primary : AppTheme.grey400,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama_pihak'] as String? ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        StatusBadge(label: isActive ? 'Aktif' : 'Nonaktif', color: isActive ? AppTheme.teal : AppTheme.grey400),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: permColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            permLabel,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: permColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppTheme.grey500),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editPermissions(item);
                                      break;
                                    case 'toggle':
                                      _toggleStatus(item);
                                      break;
                                    case 'delete':
                                      _delete(item);
                                      break;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Permission')])),
                                  PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 18), SizedBox(width: 8), Text(isActive ? 'Nonaktifkan' : 'Aktifkan')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.error))])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: AppTheme.grey100),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _InfoChip(icon: Icons.speed_outlined, label: 'Rate Limit', value: '$rateLimit/hari'),
                              _InfoChip(icon: Icons.access_time_outlined, label: 'Terakhir Dipakai', value: _formatDate(lastUsed)),
                              _InfoChip(icon: Icons.calendar_today_outlined, label: 'Dibuat', value: _formatDate(createdAt)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
        // Pagination
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PaginationRow(
              currentPage: _page,
              totalPages: _totalPages,
              onPrevious: _page > 1 ? () { _page--; _load(); } : null,
              onNext: _page < _totalPages ? () { _page++; _load(); } : null,
            ),
          ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({required this.icon, required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.grey700)),
      ],
    );
  }
}

InputDecoration inputDecoration(String label, IconData icon) {
  return AppInputDecoration.standard(label, icon, style: InputDecorationStyle.filled, fillColor: AppTheme.grey50);
}
