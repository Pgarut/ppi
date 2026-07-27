import 'package:flutter/material.dart';
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
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'Users'),
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
        _UsersTab(),
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

// ── Users Tab ──
class _UsersTab extends StatefulWidget {
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getUsers();
      if (mounted) setState(() { _users = (res['items'] as List).cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Map<String, dynamic>? edit}) {
    final userCtrl = TextEditingController(text: edit?['username']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: edit?['role']?.toString() ?? 'guru_mapel_wali_kelas');
    final guruIdCtrl = TextEditingController(text: edit?['guru_id']?.toString() ?? '');
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(edit != null ? 'Edit User' : 'Tambah User'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true,
                  decoration: InputDecoration(labelText: edit != null ? 'Password (kosongkan jika tidak diubah)' : 'Password', border: const OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: roleCtrl.text,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const ['admin', 'kepala_sekolah', 'wakil_kurikulum', 'guru_mapel_wali_kelas', 'guru_bk']
                    .map((r) => DropdownMenuItem(value: r, child: Text(UserModel.roleDisplayName(r)))).toList(),
                onChanged: (v) { roleCtrl.text = v ?? ''; setD(() {}); },
              ),
              const SizedBox(height: 12),
              TextField(controller: guruIdCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Guru ID (opsional)', border: OutlineInputBorder())),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              final body = <String, dynamic>{'username': userCtrl.text, 'role': roleCtrl.text};
              if (passCtrl.text.isNotEmpty) body['password'] = passCtrl.text;
              if (guruIdCtrl.text.isNotEmpty) body['guru_id'] = int.tryParse(guruIdCtrl.text);
              try {
                if (edit != null) {
                  await AdminService.updateUser(edit['id'] as int, body);
                } else {
                  body['password'] = passCtrl.text;
                  await AdminService.createUser(body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await showConfirmDialog(context, title: 'Hapus User', message: 'Yakin hapus user ini?');
    if (!ok) return;
    try {
      await AdminService.deleteUser(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add, size: 18), label: const Text('Tambah User')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _users.isEmpty
            ? Center(child: Text('Belum ada user.', style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i];
                  return Card(
                    child: ListTile(
                      title: Text(u['username']?.toString() ?? ''),
                      subtitle: Text('Role: ${UserModel.roleDisplayName(u['role']?.toString() ?? '')} | Aktif: ${u['is_active'] == 1 ? 'Ya' : 'Tidak'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(edit: u)),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(u['id'] as int)),
                      ]),
                    ),
                  );
                },
              )),
      ]),
    );
  }
}

// ── Hak Akses Tab ──
class _HakAksesTab extends StatefulWidget {
  @override
  State<_HakAksesTab> createState() => _HakAksesTabState();
}

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
    final roleCtrl = TextEditingController();
    final modulCtrl = TextEditingController();
    final aksiCtrl = TextEditingController(text: 'view');
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah Hak Akses'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const ['admin', 'kepala_sekolah', 'wakil_kurikulum', 'guru_mapel_wali_kelas', 'guru_bk']
                  .map((r) => DropdownMenuItem(value: r, child: Text(UserModel.roleDisplayName(r)))).toList(),
              onChanged: (v) { roleCtrl.text = v ?? ''; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Modul', border: OutlineInputBorder()),
              items: const ['dashboard', 'master_data', 'penjadwalan', 'absensi', 'nilai', 'rapor', 'pengaduan', 'konseling', 'bakat_minat', 'kenaikan_kelas', 'alumni', 'users', 'pengaturan', 'laporan']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) { modulCtrl.text = v ?? ''; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Aksi', border: OutlineInputBorder()),
              items: const ['view', 'create', 'edit', 'delete', 'validate']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { aksiCtrl.text = v ?? ''; setD(() {}); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await AdminService.addHakAkses({'role': roleCtrl.text, 'modul': modulCtrl.text, 'aksi': aksiCtrl.text});
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
                  return Card(child: ListTile(
                    title: Text('${UserModel.roleDisplayName(item['role']?.toString() ?? '')} — ${item['modul']} — ${item['aksi']}'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => _delete(item['id'] as int)),
                  ));
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
                  return Card(child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.history, size: 18),
                    ),
                    title: Text('${log['username'] ?? '-'} — ${log['aksi']}', style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${log['modul'] ?? '-'} | ${log['detail'] ?? '-'} | ${log['created_at'] ?? '-'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ));
                },
              )),
        if (_totalPages > 1) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page > 1 ? () { _page--; _load(); } : null),
          Text('$_page / $_totalPages'),
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

  Future<void> _doBackup() async {
    setState(() => _loading = true);
    try {
      await AdminService.backup();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup berhasil!')));
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.backup, size: 64, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          Text('Backup Database', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Melakukan backup seluruh data ke format JSON.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _doBackup,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.backup),
            label: const Text('Backup Sekarang'),
          ),
        ]),
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

  Future<void> _doRestore() async {
    setState(() => _loading = true);
    try {
      await AdminService.restore({});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore berhasil!')));
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.restore, size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 24),
          Text('Restore Database', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Mengembalikan data dari file backup JSON.', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _doRestore,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.restore),
            label: const Text('Restore Sekarang'),
          ),
        ]),
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
  final _namaCtrl = TextEditingController(text: 'Madrasah PPI');
  final _alamatCtrl = TextEditingController(text: '');
  final _telpCtrl = TextEditingController(text: '');
  final _emailCtrl = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Profil Sekolah', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Sekolah', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _alamatCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _telpCtrl, decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sekolah tersimpan')));
          }, icon: const Icon(Icons.save), label: const Text('Simpan Profil')),
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
  void initState() {
    super.initState();
    _load();
  }

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
    _heroTitleCtrl.dispose();
    _heroSubtitleCtrl.dispose();
    _logoUrlCtrl.dispose();
    _bgUrlCtrl.dispose();
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
          Text('Tampilan Halaman Login', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(controller: _heroTitleCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Judul Hero', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _heroSubtitleCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Subtitle Hero', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _logoUrlCtrl, decoration: const InputDecoration(labelText: 'URL Logo', border: OutlineInputBorder(), hintText: 'https://...')),
          const SizedBox(height: 16),
          TextField(controller: _bgUrlCtrl, decoration: const InputDecoration(labelText: 'URL Background', border: OutlineInputBorder(), hintText: 'https://...')),
          const SizedBox(height: 24),
          Row(children: [
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan')),
            const SizedBox(width: 16),
            OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
          ]),
          const SizedBox(height: 32),
          Text('Pratinjau', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
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
                Text(_heroTitleCtrl.text.isNotEmpty ? _heroTitleCtrl.text : 'Judul', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_heroSubtitleCtrl.text.isNotEmpty ? _heroSubtitleCtrl.text : 'Subtitle', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
