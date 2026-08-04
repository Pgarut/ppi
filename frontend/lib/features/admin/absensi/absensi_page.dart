import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
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
            Tab(text: 'Asatidz', icon: Icon(Icons.person_outlined, size: 18)),
            Tab(text: 'Santri', icon: Icon(Icons.people_outlined, size: 18)),
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

  Widget _buildMonitoringTab(bool isGuru) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilterCard(children: [
          SizedBox(
            width: 200,
            child: TextField(
              decoration: inputDecoration('Tanggal (YYYY-MM-DD)', Icons.calendar_today_outlined),
              onChanged: (v) { _filterTanggal = v; },
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              isDense: true,
              decoration: inputDecoration('Status', Icons.filter_alt_outlined),
              items: ['', 'hadir', 'izin', 'sakit', 'alpa'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                  child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { _statusFilter = v ?? ''; },
            ),
          ),
          FilledButton.icon(
            onPressed: () { _page = 1; _load(); },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Cari'),
          ),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _data.isEmpty
              ? const EmptyState(message: 'Tidak ada data absensi.')
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: _data.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _data.length) {
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
                    final d = _data[i];
                    final st = d['status'] as String? ?? '';
                    final nama = d[isGuru ? 'guru_nama' : 'siswa_nama'] as String? ?? '-';
                    final subtitle = isGuru
                        ? '${d['tanggal'] ?? '-'} | ${d['jam_masuk'] ?? '-'} - ${d['jam_keluar'] ?? '-'}'
                        : '${d['tanggal'] ?? '-'} | ${d['kelas_nama'] ?? '-'}${d['mapel_nama'] != null ? ' | ${d['mapel_nama']}' : ''}';
                    final statusColor = AttendanceStatus.colorFor(st);
                    return Card(
                      margin: const EdgeInsets.only(top: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(radius: 22, backgroundColor: statusColor.withValues(alpha: 0.12),
                            child: Text(nama.isNotEmpty ? nama[0] : '?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.grey800)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
                          ])),
                          AttendanceStatus.fromString(st),
                        ]),
                      ),
                    );
                  },
                )),
    ]);
  }

  Widget _buildRekapTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      FilterCard(children: [
        SizedBox(
          width: 240,
          child: TextField(
            decoration: inputDecoration('Tanggal Mulai (YYYY-MM-DD)', Icons.date_range_outlined),
            onChanged: (v) { _filterTanggal = v; },
          ),
        ),
        FilledButton.icon(
          onPressed: () { _page = 1; _load(); },
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Tampilkan'),
        ),
      ]),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator(color: AppTheme.primary))
      else if (_rekap == null)
        const EmptyState(icon: Icons.filter_list_outlined, message: 'Masukkan tanggal untuk melihat rekap.')
      else ...[
        _rekapCard('Absensi Santri', _rekap!['siswa'] as Map<String, dynamic>? ?? {},
            _rekap!['total_siswa'] as int? ?? 0, Icons.people_outlined),
        const SizedBox(height: 12),
        _rekapCard('Absensi Asatidz', _rekap!['guru'] as Map<String, dynamic>? ?? {},
            _rekap!['total_guru'] as int? ?? 0, Icons.person_outlined),
      ],
    ]));
  }

  Widget _rekapCard(String title, Map<String, dynamic> data, int total, IconData icon) {
    return DataCard(
      header: Row(children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.grey800)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (data.isEmpty)
          const EmptyState(icon: Icons.inbox_outlined, message: 'Belum ada data.')
        else
          ...(data.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
            Text(e.key, style: const TextStyle(fontSize: 13, color: AppTheme.grey700)),
            const Spacer(),
            StatusBadge(label: '${e.value}', color: AttendanceStatus.colorFor(e.key)),
          ])))),
        const Divider(height: 20, color: AppTheme.grey200),
        Row(children: [
          const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey800)),
          const Spacer(),
          Text('$total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
      ]),
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
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      FilterCard(children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _tglMulaiCtrl,
            decoration: inputDecoration('Tanggal Mulai', Icons.date_range_outlined),
          ),
        ),
        SizedBox(
          width: 200,
          child: TextField(
            controller: _tglSelesaiCtrl,
            decoration: inputDecoration('Tanggal Selesai', Icons.date_range_outlined, optional: true),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: _kelasId,
            isDense: true,
            decoration: inputDecoration('Kelas', Icons.school_outlined, optional: true),
            items: [const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas', style: TextStyle(fontSize: 13))),
              ..._kelasList.map((k) => DropdownMenuItem(value: '${k['id']}', child: Text('${k['nama']}', style: const TextStyle(fontSize: 13))))],
            onChanged: (v) => setState(() => _kelasId = v),
          ),
        ),
        FilledButton.icon(
          onPressed: _loadAnalisis,
          icon: const Icon(Icons.analytics, size: 18),
          label: const Text('Analisis'),
        ),
      ]),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator(color: AppTheme.primary))
      else if (_analisis != null) ...[
        _buildOverview(),
        const SizedBox(height: 16),
        _buildPerStatus(),
        const SizedBox(height: 16),
        _buildSiswaPerKelas(),
        const SizedBox(height: 16),
        _buildPerBulan(),
      ] else
        const EmptyState(icon: Icons.analytics_outlined, message: 'Masukkan filter dan klik Analisis.'),
    ]));
  }

  Widget _buildOverview() {
    final o = _analisis!['overview'] as Map<String, dynamic>? ?? {};
    return DataCard(
      header: const Row(children: [
        Icon(Icons.summarize_outlined, size: 20, color: AppTheme.primary),
        SizedBox(width: 8),
        Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.grey800)),
      ]),
      child: Wrap(spacing: 16, runSpacing: 16, children: [
        StatChip(label: 'Entry Santri', value: '${o['total_siswa_entry'] ?? 0}', color: AppTheme.blue),
        StatChip(label: 'Entry Asatidz', value: '${o['total_guru_entry'] ?? 0}', color: AppTheme.teal),
      ]),
    );
  }

  Widget _buildPerStatus() {
    final siswa = _analisis!['siswa_per_status'] as Map<String, dynamic>? ?? {};
    final guru = _analisis!['guru_per_status'] as Map<String, dynamic>? ?? {};
    final statuses = ['hadir', 'izin', 'sakit', 'alpa'];
    if (statuses.every((s) => (siswa[s] ?? 0) == 0 && (guru[s] ?? 0) == 0)) return const SizedBox.shrink();
    return ModernTable(
      columns: const [
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Santri'), numeric: true),
        DataColumn(label: Text('Asatidz'), numeric: true),
      ],
      rows: statuses.map((s) {
        final c = AttendanceStatus.colorFor(s);
        return DataRow(cells: [
          DataCell(Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(s, style: const TextStyle(fontSize: 12)),
          ])),
          DataCell(Text('${siswa[s] ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
          DataCell(Text('${guru[s] ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
        ]);
      }).toList(),
    );
  }

  Widget _buildSiswaPerKelas() {
    final list = (_analisis!['siswa_per_kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    final kelasGroup = <String, Map<String, int>>{};
    for (final item in list) {
      final kn = item['kelas_nama'] as String? ?? '-';
      kelasGroup.putIfAbsent(kn, () => {});
      kelasGroup[kn]![item['status'] as String? ?? ''] = (item['count'] as int?) ?? 0;
    }
    return DataCard(
      header: const Row(children: [
        Icon(Icons.school_outlined, size: 20, color: AppTheme.primary),
        SizedBox(width: 8),
        Text('Santri Per Kelas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.grey800)),
      ]),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
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
          DataCell(Text('${e.value['hadir'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.primary))),
          DataCell(Text('${e.value['izin'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.orange))),
          DataCell(Text('${e.value['sakit'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.blue))),
          DataCell(Text('${e.value['alpa'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.error))),
        ])).toList(),
      )),
    );
  }

  Widget _buildPerBulan() {
    final list = (_analisis!['per_bulan'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return DataCard(
      header: const Row(children: [
        Icon(Icons.trending_up, size: 20, color: AppTheme.primary),
        SizedBox(width: 8),
        Text('Tren Bulanan (Santri)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.grey800)),
      ]),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
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
          DataCell(Text('${b['hadir'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.primary))),
          DataCell(Text('${b['izin'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.orange))),
          DataCell(Text('${b['sakit'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.blue))),
          DataCell(Text('${b['alpa'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppTheme.error))),
          DataCell(Text('${b['total'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ])).toList(),
      )),
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
      case 'create': return AppTheme.primary;
      case 'update': return AppTheme.orange;
      case 'delete': return AppTheme.error;
      case 'hadir': return AppTheme.primary;
      case 'izin': return AppTheme.orange;
      case 'sakit': return AppTheme.blue;
      case 'alpa': return AppTheme.error;
      default: return AppTheme.grey400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _items.isEmpty
            ? const EmptyState(icon: Icons.history, message: 'Belum ada aktivitas absensi.')
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: c.withValues(alpha: 0.12),
                          child: Icon(_iconForAksi(aksi), size: 20, color: c)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            StatusBadge(label: aksi, color: c),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d['detail'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.grey700), overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.person_outline, size: 12, color: AppTheme.grey400),
                            const SizedBox(width: 4),
                            Text('${d['username'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 12, color: AppTheme.grey400),
                            const SizedBox(width: 4),
                            Text('${d['created_at'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                          ]),
                        ])),
                      ]),
                    ),
                  );
                },
              );
  }
}

// ── Shared Input Decoration ──
InputDecoration inputDecoration(String label, IconData icon, {bool optional = false}) {
  return AppInputDecoration.standard(label, icon, optional: optional);
}
