import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class RaporPage extends StatefulWidget {
  const RaporPage({super.key});

  @override
  State<RaporPage> createState() => _RaporPageState();
}

class _RaporPageState extends State<RaporPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_tabCtrl.index == 3) {
        final res = await AdminService.getArsipRapor(page: _page);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      } else if (_tabCtrl.index == 0) {
        final res = await AdminService.getRapor(page: _page, statusKirim: _statusFilter.isEmpty ? null : _statusFilter);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      }
    } catch (_) { _data = []; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cetak(int id) async {
    try {
      await AdminService.cetakRapor(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor dicetak dan diarsipkan'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cetak: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapor'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) { _page = 1; _load(); }, isScrollable: true,
          tabs: const [
            Tab(text: 'Monitoring', icon: Icon(Icons.visibility_outlined, size: 18)),
            Tab(text: 'Analisis', icon: Icon(Icons.analytics_outlined, size: 18)),
            Tab(text: 'Audit', icon: Icon(Icons.history, size: 18)),
            Tab(text: 'Arsip', icon: Icon(Icons.archive_outlined, size: 18)),
          ],
        ),
      ),
      body: IndexedStack(index: _tabCtrl.index, children: [
        _buildMonitoringTab(),
        const _AnalisisTab(),
        const _AuditTab(),
        _buildArsipTab(),
      ]),
    );
  }

  Widget _buildPagination() {
    if (_page >= _totalPages) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () { _page++; _load(); },
          icon: const Icon(Icons.expand_more, size: 18),
          label: const Text('Muat lebih banyak'),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'divalidasi': return Colors.green;
      case 'terkirim': return Colors.blue;
      default: return Colors.orange;
    }
  }

  Widget _statusBadge(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMonitoringTab() {
    return Column(children: [
      _FormCard(title: 'Filter', icon: Icons.filter_list, children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _statusFilter.isEmpty ? null : _statusFilter,
            isDense: true,
            decoration: _inpDeco('Status Kirim', Icons.send_outlined),
            items: ['', 'draft', 'terkirim', 'divalidasi'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
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
              ? Center(child: Text('Tidak ada data rapor.', style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: _data.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _data.length) return _buildPagination();
                    final d = _data[i];
                    final statusKirim = d['status_kirim'] as String? ?? 'draft';
                    return Card(
                      margin: const EdgeInsets.only(top: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(radius: 22, backgroundColor: _statusColor(statusKirim).withValues(alpha: 0.12),
                            child: Text((d['siswa_nama'] as String? ?? '?')[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(statusKirim)))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${d['siswa_nama'] ?? '-'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.book_outlined, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('${d['mapel_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              Icon(Icons.school_outlined, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('${d['kelas_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ]),
                            const SizedBox(height: 2),
                            Text('${d['semester_nama'] ?? '-'} | Predikat: ${d['predikat'] ?? '-'}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            _statusBadge(statusKirim),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton.icon(
                                onPressed: () => _cetak(d['id'] as int),
                                icon: const Icon(Icons.print_outlined, size: 14),
                                label: const Text('Cetak', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    );
                  },
                )),
    ]);
  }

  Widget _buildArsipTab() {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _data.isEmpty
            ? Center(child: Text('Tidak ada data arsip.', style: TextStyle(color: Colors.grey[500])))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _data.length + 1,
                itemBuilder: (_, i) {
                  if (i == _data.length) return _buildPagination();
                  final d = _data[i];
                  return Card(
                    margin: const EdgeInsets.only(top: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: Colors.blueGrey.withValues(alpha: 0.12),
                          child: Text((d['siswa_nama'] as String? ?? '?')[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['siswa_nama'] as String? ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${d['semester_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ])),
                        Icon(Icons.check_circle_outline, size: 18, color: Colors.green[400]),
                        const SizedBox(width: 4),
                        Text('${d['dicetak_pada'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ]),
                    ),
                  );
                },
              );
  }
}

// ── Analisis Tab ──
class _AnalisisTab extends StatefulWidget {
  const _AnalisisTab();
  @override
  State<_AnalisisTab> createState() => _AnalisisTabState();
}

class _AnalisisTabState extends State<_AnalisisTab> {
  List<Map<String, dynamic>> _semesterList = [];
  List<Map<String, dynamic>> _kelasList = [];
  String? _semesterId;
  String? _kelasId;
  Map<String, dynamic>? _analisis;
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadRef(); }

  Future<void> _loadRef() async {
    try {
      final res = await AdminService.getReferensi();
      setState(() {
        _semesterList = (res['semester'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _kelasList = (res['kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (_) {}
  }

  Future<void> _loadAnalisis() async {
    if (_semesterId == null) return;
    setState(() => _loading = true);
    try {
      _analisis = await AdminService.getAnalisisRapor(semesterId: _semesterId!, kelasId: _kelasId);
    } catch (_) { _analisis = null; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _FormCard(title: 'Filter Analisis', icon: Icons.analytics_outlined, children: [
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _semesterId,
            isDense: true,
            decoration: _inpDeco('Semester', Icons.calendar_month_outlined),
            items: _semesterList.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _semesterId = v),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _kelasId,
            isDense: true,
            decoration: _inpDeco('Kelas', Icons.school_outlined, optional: true),
            items: [const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas', style: TextStyle(fontSize: 13))),
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
        _buildPerMapel(theme),
        const SizedBox(height: 16),
        _buildPerKelas(theme),
      ] else if (_semesterId != null)
        Center(child: Text('Pilih semester dan klik Analisis.', style: TextStyle(color: Colors.grey[500])))
      else
        Center(child: Text('Pilih semester untuk memulai.', style: TextStyle(color: Colors.grey[500]))),
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
          _statChip(Icons.people_outline, 'Siswa', '${o['total_siswa'] ?? 0}', Colors.blue),
          _statChip(Icons.book_outlined, 'Mapel', '${o['total_mapel'] ?? 0}', Colors.teal),
          _statChip(Icons.trending_up, 'Rata-rata', '${o['rata_rata'] ?? '-'}', Colors.green),
          _statChip(Icons.arrow_upward, 'Tertinggi', '${o['nilai_tertinggi'] ?? '-'}', Colors.orange),
          _statChip(Icons.arrow_downward, 'Terendah', '${o['nilai_terendah'] ?? '-'}', Colors.red),
          _statChip(Icons.list, 'Total Entry', '${o['total_entries'] ?? 0}', Colors.grey),
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

  Widget _buildPerMapel(ThemeData theme) {
    final list = (_analisis!['per_mapel'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.book_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Per Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Mapel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Rata-rata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('C', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((m) => DataRow(cells: [
            DataCell(Text('${m['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${m['avg_nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text('${m['predikat_a'] ?? 0}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${m['predikat_b'] ?? 0}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${m['predikat_c'] ?? 0}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${m['predikat_d'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ])).toList(),
        )),
      ])),
    );
  }

  Widget _buildPerKelas(ThemeData theme) {
    final list = (_analisis!['per_kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Per Kelas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Rata-rata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Siswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((k) => DataRow(cells: [
            DataCell(Text('${k['kelas_nama'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${k['avg_nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text('${k['jumlah_siswa'] ?? 0}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${k['count'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ])).toList(),
        ),
      ])),
    );
  }
}

// ── Audit Tab ──
class _AuditTab extends StatefulWidget {
  const _AuditTab();
  @override
  State<_AuditTab> createState() => _AuditTabState();
}

class _AuditTabState extends State<_AuditTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getAuditRapor(page: _page);
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
      case 'cetak': return Icons.print_outlined;
      default: return Icons.info_outline;
    }
  }

  Color _colorForAksi(String aksi) {
    switch (aksi) {
      case 'create': return Colors.green;
      case 'update': return Colors.orange;
      case 'delete': return Colors.red;
      case 'cetak': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? Center(child: Text('Belum ada aktivitas rapor.', style: TextStyle(color: Colors.grey[500])))
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
