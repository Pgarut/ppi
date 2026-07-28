import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _rekap;
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _filterTanggal = '';
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 5, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final idx = _tabCtrl.index;
      if (idx == 2) {
        _rekap = await AdminService.getRekapAbsensi(tanggalMulai: _filterTanggal);
      } else if (idx < 2) {
        final res = idx == 0
            ? await AdminService.getAbsensiGuru(page: _page, tanggal: _filterTanggal, status: _statusFilter)
            : await AdminService.getAbsensiSiswa(page: _page, tanggal: _filterTanggal, status: _statusFilter, kelasId: _filterTanggal);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      }
    } catch (_) { _data = []; _rekap = null; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) { _page = 1; _load(); }, isScrollable: true,
          tabs: const [
            Tab(text: 'Guru', icon: Icon(Icons.person_outlined, size: 18)),
            Tab(text: 'Siswa', icon: Icon(Icons.people_outlined, size: 18)),
            Tab(text: 'Rekap', icon: Icon(Icons.summarize_outlined, size: 18)),
            Tab(text: 'Analisis', icon: Icon(Icons.analytics_outlined, size: 18)),
            Tab(text: 'Audit', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: IndexedStack(index: _tabCtrl.index, children: [
        _buildMonitoringTab(true),
        _buildMonitoringTab(false),
        _buildRekapTab(),
        const _AnalisisAbsensiTab(),
        const _AuditAbsensiTab(),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPagination() {
    if (_page >= _totalPages) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: OutlinedButton.icon(
        onPressed: () { _page++; _load(); },
        icon: const Icon(Icons.expand_more, size: 18),
        label: const Text('Muat lebih banyak'),
      )),
    );
  }

  Widget _buildMonitoringTab(bool isGuru) {
    return Column(children: [
      _FormCard(title: isGuru ? 'Filter Absensi Guru' : 'Filter Absensi Siswa',
          icon: isGuru ? Icons.person_outlined : Icons.people_outlined, children: [
        Row(children: [
          Expanded(child: TextField(
            decoration: _inpDeco('Tanggal (YYYY-MM-DD)', Icons.calendar_today_outlined),
            onChanged: (v) { _filterTanggal = v; },
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _statusFilter.isEmpty ? null : _statusFilter,
            isDense: true,
            decoration: _inpDeco('Status', Icons.filter_alt_outlined),
            items: ['', 'hadir', 'izin', 'sakit', 'alpa'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) { _statusFilter = v ?? ''; },
          )),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () { _page = 1; _load(); },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Cari'),
          ),
        ]),
      ]),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: _data.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _data.length) return _buildPagination();
                    final d = _data[i];
                    final st = d['status'] as String? ?? '';
                    final nama = d[isGuru ? 'guru_nama' : 'siswa_nama'] as String? ?? '-';
                    final subtitle = isGuru
                        ? '${d['tanggal'] ?? '-'} | ${d['jam_masuk'] ?? '-'} - ${d['jam_keluar'] ?? '-'}'
                        : '${d['tanggal'] ?? '-'} | ${d['kelas_nama'] ?? '-'}${d['mapel_nama'] != null ? ' | ${d['mapel_nama']}' : ''}';
                    return Card(
                      margin: const EdgeInsets.only(top: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(radius: 22, backgroundColor: _statusColor(st).withValues(alpha: 0.12),
                            child: Text((nama)[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(st)))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: _statusColor(st).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text(st, style: TextStyle(fontSize: 12, color: _statusColor(st), fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                    );
                  },
                )),
    ]);
  }

  Widget _buildRekapTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _FormCard(title: 'Filter Rekap', icon: Icons.filter_list, children: [
        Row(children: [
          Expanded(child: TextField(
            decoration: _inpDeco('Tanggal Mulai (YYYY-MM-DD)', Icons.date_range_outlined),
            onChanged: (v) { _filterTanggal = v; },
          )),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () { _page = 1; _load(); },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Tampilkan'),
          ),
        ]),
      ]),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_rekap == null)
        Center(child: Text('Masukkan tanggal untuk melihat rekap.', style: TextStyle(color: Colors.grey[500])))
      else ...[
        _rekapCard('Absensi Siswa', _rekap!['siswa'] as Map<String, dynamic>? ?? {},
            _rekap!['total_siswa'] as int? ?? 0, Icons.people_outlined),
        const SizedBox(height: 12),
        _rekapCard('Absensi Guru', _rekap!['guru'] as Map<String, dynamic>? ?? {},
            _rekap!['total_guru'] as int? ?? 0, Icons.person_outlined),
      ],
    ]));
  }

  Widget _rekapCard(String title, Map<String, dynamic> data, int total, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 20, color: Colors.green[700]), const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),
        if (data.isEmpty)
          Text('Belum ada data.', style: TextStyle(fontSize: 13, color: Colors.grey[500]))
        else
          ...(data.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
            Text(e.key, style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: _statusColor(e.key).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('${e.value}', style: TextStyle(fontSize: 12, color: _statusColor(e.key), fontWeight: FontWeight.w600))),
          ])))),
        const Divider(height: 20),
        Row(children: [const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(), Text('$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700]))]),
      ])),
    );
  }
}

// ── Analisis Absensi Tab ──
class _AnalisisAbsensiTab extends StatefulWidget {
  const _AnalisisAbsensiTab();
  @override
  State<_AnalisisAbsensiTab> createState() => _AnalisisAbsensiTabState();
}

class _AnalisisAbsensiTabState extends State<_AnalisisAbsensiTab> {
  List<Map<String, dynamic>> _kelasList = [];
  final _tglMulaiCtrl = TextEditingController();
  final _tglSelesaiCtrl = TextEditingController();
  String? _kelasId;
  Map<String, dynamic>? _analisis;
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadRef(); }

  @override
  void dispose() { _tglMulaiCtrl.dispose(); _tglSelesaiCtrl.dispose(); super.dispose(); }

  Future<void> _loadRef() async {
    try {
      final res = await AdminService.getReferensi();
      setState(() => _kelasList = (res['kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? []);
    } catch (_) {}
  }

  Future<void> _loadAnalisis() async {
    setState(() => _loading = true);
    try {
      _analisis = await AdminService.getAnalisisAbsensi(
        tanggalMulai: _tglMulaiCtrl.text.isEmpty ? null : _tglMulaiCtrl.text,
        tanggalSelesai: _tglSelesaiCtrl.text.isEmpty ? null : _tglSelesaiCtrl.text,
        kelasId: _kelasId,
      );
    } catch (_) { _analisis = null; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _FormCard(title: 'Filter Analisis', icon: Icons.analytics_outlined, children: [
        Row(children: [
          Expanded(child: TextField(
            controller: _tglMulaiCtrl,
            decoration: _inpDeco('Tanggal Mulai', Icons.date_range_outlined),
          )),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _tglSelesaiCtrl,
            decoration: _inpDeco('Tanggal Selesai', Icons.date_range_outlined, optional: true),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _kelasId,
            isDense: true,
            decoration: _inpDeco('Kelas', Icons.school_outlined, optional: true),
            items: [DropdownMenuItem<String>(value: null, child: Text('Semua Kelas', style: TextStyle(fontSize: 13))),
              ..._kelasList.map((k) => DropdownMenuItem(value: '${k['id']}', child: Text('${k['nama']}', style: const TextStyle(fontSize: 13))))],
            onChanged: (v) => setState(() => _kelasId = v),
          )),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _loadAnalisis,
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('Analisis'),
          ),
        ]),
      ]),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_analisis != null) ...[
        _buildOverview(theme),
        const SizedBox(height: 16),
        _buildPerStatus(theme),
        const SizedBox(height: 16),
        _buildSiswaPerKelas(theme),
        const SizedBox(height: 16),
        _buildPerBulan(theme),
      ] else
        Center(child: Text('Masukkan filter dan klik Analisis.', style: TextStyle(color: Colors.grey[500]))),
    ]));
  }

  Widget _buildOverview(ThemeData theme) {
    final o = _analisis!['overview'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.summarize_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _statChip(Icons.people_outlined, 'Entry Siswa', '${o['total_siswa_entry'] ?? 0}', Colors.blue),
          _statChip(Icons.person_outlined, 'Entry Guru', '${o['total_guru_entry'] ?? 0}', Colors.teal),
        ]),
      ])),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }

  Color _absStatusColor(String s) {
    switch (s) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPerStatus(ThemeData theme) {
    final siswa = _analisis!['siswa_per_status'] as Map<String, dynamic>? ?? {};
    final guru = _analisis!['guru_per_status'] as Map<String, dynamic>? ?? {};
    final statuses = ['hadir', 'izin', 'sakit', 'alpa'];
    if (statuses.every((s) => (siswa[s] ?? 0) == 0 && (guru[s] ?? 0) == 0)) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.pie_chart_outline, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Distribusi Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Siswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Guru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: statuses.map((s) => DataRow(cells: [
            DataCell(Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _absStatusColor(s), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(s, style: const TextStyle(fontSize: 12)),
            ])),
            DataCell(Text('${siswa[s] ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _absStatusColor(s)))),
            DataCell(Text('${guru[s] ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _absStatusColor(s)))),
          ])).toList(),
        ),
      ])),
    );
  }

  Widget _buildSiswaPerKelas(ThemeData theme) {
    final list = (_analisis!['siswa_per_kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    final kelasGroup = <String, Map<String, int>>{};
    for (final item in list) {
      final kn = item['kelas_nama'] as String? ?? '-';
      kelasGroup.putIfAbsent(kn, () => {});
      kelasGroup[kn]![item['status'] as String? ?? ''] = (item['count'] as int?) ?? 0;
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Siswa Per Kelas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Hadir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Izin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Sakit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Alpa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: kelasGroup.entries.map((e) => DataRow(cells: [
            DataCell(Text(e.key, style: const TextStyle(fontSize: 12))),
            DataCell(Text('${e.value['hadir'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.green))),
            DataCell(Text('${e.value['izin'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.orange))),
            DataCell(Text('${e.value['sakit'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.blue))),
            DataCell(Text('${e.value['alpa'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.red))),
          ])).toList(),
        )),
      ])),
    );
  }

  Widget _buildPerBulan(ThemeData theme) {
    final list = (_analisis!['per_bulan'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Tren Bulanan (Siswa)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Bulan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Hadir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Izin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Sakit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Alpa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((b) => DataRow(cells: [
            DataCell(Text('${b['bulan'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${b['hadir'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.green))),
            DataCell(Text('${b['izin'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.orange))),
            DataCell(Text('${b['sakit'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.blue))),
            DataCell(Text('${b['alpa'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.red))),
            DataCell(Text('${b['total'] ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ])).toList(),
        )),
      ])),
    );
  }
}

// ── Audit Absensi Tab ──
class _AuditAbsensiTab extends StatefulWidget {
  const _AuditAbsensiTab();
  @override
  State<_AuditAbsensiTab> createState() => _AuditAbsensiTabState();
}

class _AuditAbsensiTabState extends State<_AuditAbsensiTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getAuditAbsensi(page: _page);
      _items = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      _totalPages = res['pagination']?['total_pages'] ?? 1;
    } catch (_) { _items = []; }
    if (mounted) setState(() => _loading = false);
  }

  IconData _iconForAksi(String aksi) {
    switch (aksi) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'hadir': case 'izin': case 'sakit': case 'alpa': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  Color _colorForAksi(String aksi) {
    switch (aksi) {
      case 'create': return Colors.green;
      case 'update': return Colors.orange;
      case 'delete': return Colors.red;
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? Center(child: Text('Belum ada aktivitas absensi.', style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length + 1,
                itemBuilder: (_, i) {
                  if (i == _items.length) {
                    if (_page >= _totalPages) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: OutlinedButton.icon(
                        onPressed: () { _page++; _load(); },
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: const Text('Muat lebih banyak'),
                      )),
                    );
                  }
                  final d = _items[i];
                  final aksi = d['aksi'] as String? ?? '';
                  final c = _colorForAksi(aksi);
                  return Card(
                    margin: const EdgeInsets.only(top: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: c.withValues(alpha: 0.12),
                          child: Icon(_iconForAksi(aksi), size: 20, color: c)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(aksi, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d['detail'] as String? ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('${d['username'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text('${d['created_at'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ]),
                        ])),
                      ]),
                    ),
                  );
                },
              );
  }
}

// ── Shared Helpers ──

InputDecoration _inpDeco(String label, IconData icon, {bool optional = false}) {
  return InputDecoration(
    labelText: label,
    hintText: optional ? 'Opsional' : null,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
