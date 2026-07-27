import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  int _selectedTab = 0;

  final _tabs = [
    _TabCfg('Tahun Ajaran', 'tahun-ajaran', Icons.calendar_month_outlined, ['nama', 'tanggal_mulai', 'tanggal_selesai', 'is_aktif'],
        ['Nama', 'Tgl Mulai', 'Tgl Selesai', 'Aktif']),
    _TabCfg('Semester', 'semester', Icons.layers_outlined, ['tahun_ajaran_id', 'nama', 'is_aktif'], ['Tahun Ajaran ID', 'Nama', 'Aktif']),
    _TabCfg('Jurusan', 'jurusan', Icons.category_outlined, ['nama', 'kode'], ['Nama', 'Kode']),
    _TabCfg('Tingkat', 'tingkat', Icons.stairs_outlined, ['nama', 'jenjang'], ['Nama', 'Jenjang']),
    _TabCfg('Kelas', 'kelas', Icons.meeting_room_outlined, ['nama', 'tingkat_id', 'jurusan_id', 'tahun_ajaran_id'],
        ['Nama', 'Tingkat ID', 'Jurusan ID', 'Thn Ajaran ID']),
    _TabCfg('Mata Pelajaran', 'mata-pelajaran', Icons.book_outlined, ['nama', 'kode', 'jenjang'], ['Nama', 'Kode', 'Jenjang']),
    _TabCfg('Guru', 'guru', Icons.people_outline, ['nip', 'nama', 'jenis_kelamin', 'no_hp', 'email', 'jabatan'],
        ['NIP', 'Nama', 'JK', 'No HP', 'Email', 'Jabatan']),
    _TabCfg('Wali Kelas', 'guru', Icons.supervisor_account_outlined, ['nip', 'nama', 'jenis_kelamin', 'no_hp', 'email'],
        ['NIP', 'Nama', 'JK', 'No HP', 'Email']),
    _TabCfg('Guru BK', 'guru', Icons.psychology_outlined, ['nip', 'nama', 'jenis_kelamin', 'no_hp', 'email'],
        ['NIP', 'Nama', 'JK', 'No HP', 'Email']),
    _TabCfg('Siswa', 'siswa', Icons.person_outline, ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'status'],
        ['NIS', 'NISN', 'Nama', 'JK', 'Kelas ID', 'Status']),
    _TabCfg('Ruangan', 'ruangan', Icons.room_outlined, ['nama', 'kapasitas'], ['Nama', 'Kapasitas']),
  ];

  final Map<int, List<Map<String, dynamic>>> _data = {};
  final Map<int, bool> _loading = {};
  final Map<int, int> _page = {};
  final Map<int, int> _totalPages = {};
  final Map<int, String?> _error = {};
  final Map<int, TextEditingController> _searchCtrl = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabs.length; i++) {
      _data[i] = [];
      _loading[i] = false;
      _page[i] = 1;
      _totalPages[i] = 1;
      _searchCtrl[i] = TextEditingController();
    }
    _load(0);
  }

  @override
  void dispose() {
    for (final c in _searchCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _load(int idx, {bool refresh = false}) async {
    if (refresh) _page[idx] = 1;
    setState(() { _loading[idx] = true; _error[idx] = null; });
    try {
      final filters = <String, String>{};
      if (idx == 7) filters['jabatan'] = 'wali_kelas';
      if (idx == 8) filters['jabatan'] = 'guru_bk';
      final res = await AdminService.list(_tabs[idx].resource,
          page: _page[idx]!, perPage: 20, search: _searchCtrl[idx]!.text, filters: filters);
      if (mounted) setState(() {
        _data[idx] = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages[idx] = res['pagination']?['total_pages'] ?? 1;
        _loading[idx] = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error[idx] = e.toString(); _loading[idx] = false; });
    }
  }

  Future<void> _showForm(int idx, {Map<String, dynamic>? edit}) {
    final cfg = _tabs[idx];
    final ctrls = <String, TextEditingController>{};
    for (final col in cfg.columns) {
      ctrls[col] = TextEditingController(text: edit?[col]?.toString() ?? '');
    }

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit != null ? 'Edit ${cfg.label}' : 'Tambah ${cfg.label}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: cfg.columns.map((col) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrls[col],
                decoration: InputDecoration(labelText: col, border: const OutlineInputBorder()),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final body = <String, dynamic>{};
              for (final col in cfg.columns) {
                body[col] = ctrls[col]!.text;
              }
              try {
                if (edit != null) {
                  await AdminService.update(cfg.resource, edit['id'] as int, body);
                } else {
                  await AdminService.create(cfg.resource, body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load(idx, refresh: true);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int idx, int id) async {
    final ok = await showConfirmDialog(context, title: 'Hapus', message: 'Yakin hapus ${_tabs[idx].label} ini?');
    if (!ok) return;
    try {
      await AdminService.delete(_tabs[idx].resource, id);
      _load(idx, refresh: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  String _displayValue(String col, dynamic val) {
    if (val == null) return '-';
    if (col == 'is_aktif' || col == 'status_aktif') return val == 1 ? 'Ya' : 'Tidak';
    if (col == 'jenis_kelamin') return val == 'L' ? 'Laki-laki' : 'Perempuan';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data'), automaticallyImplyLeading: false),
      body: Row(children: [
        SizedBox(width: 200, child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _tabs.length,
          itemBuilder: (_, i) {
            final t = _tabs[i];
            final isActive = _selectedTab == i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(t.icon, size: 20, color: isActive ? Theme.of(context).colorScheme.primary : null),
                title: Text(t.label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : null)),
                selected: isActive,
                onTap: () {
                  setState(() => _selectedTab = i);
                  if (_data[i]!.isEmpty && _loading[i] == false) _load(i);
                },
              ),
            );
          },
        )),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    final idx = _selectedTab;
    final cfg = _tabs[idx];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(cfg.label, style: Theme.of(context).textTheme.titleLarge),
          Row(children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchCtrl[idx],
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _load(idx, refresh: true),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showForm(idx),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _buildTable(idx, cfg)),
      ]),
    );
  }

  Widget _buildTable(int idx, _TabCfg cfg) {
    if (_loading[idx] == true) return const Center(child: CircularProgressIndicator());
    if (_error[idx] != null) return Center(child: Text(_error[idx]!, style: const TextStyle(color: Colors.red)));
    if (_data[idx]!.isEmpty) return Center(child: Text('Belum ada data.', style: TextStyle(color: Colors.grey[500])));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [
        Expanded(child: ListView.separated(
          itemCount: _data[idx]!.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final row = _data[idx]![i];
            return ListTile(
              dense: true,
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: cfg.displayCols.asMap().entries.map((e) {
                  final col = cfg.columns[e.key];
                  final val = _displayValue(col, row[col]);
                  return Container(
                    width: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(val, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                  );
                }).toList()),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(idx, edit: row)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () => _delete(idx, row['id'] as int)),
              ]),
            );
          },
        )),
        if (_totalPages[idx]! > 1) Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page[idx]! > 1 ? () {
              _page[idx] = _page[idx]! - 1;
              _load(idx);
            } : null),
            Text('Halaman ${_page[idx]} dari ${_totalPages[idx]}'),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page[idx]! < _totalPages[idx]! ? () {
              _page[idx] = _page[idx]! + 1;
              _load(idx);
            } : null),
          ]),
        ),
      ]),
    );
  }
}

class _TabCfg {
  final String label;
  final String resource;
  final IconData icon;
  final List<String> columns;
  final List<String> displayCols;
  _TabCfg(this.label, this.resource, this.icon, this.columns, this.displayCols);
}
