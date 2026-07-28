import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../services/wakil_kurikulum_service.dart';

class AbsensiPageWK extends StatefulWidget {
  const AbsensiPageWK({super.key});

  @override
  State<AbsensiPageWK> createState() => _AbsensiPageWKState();
}

class _AbsensiPageWKState extends State<AbsensiPageWK> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Monitoring Absensi', style: Theme.of(context).textTheme.headlineSmall),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.green[800],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[800],
          tabs: const [
            Tab(text: 'Asatidz'),
            Tab(text: 'Santri'),
            Tab(text: 'Rekap'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TabGuru(),
              _TabSiswa(),
              _TabRekap(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabGuru extends StatefulWidget {
  const _TabGuru();

  @override
  State<_TabGuru> createState() => _TabGuruState();
}

class _TabGuruState extends State<_TabGuru> {
  final _tanggalCtl = TextEditingController();
  String? _status;
  List<dynamic> _items = [];
  bool _loading = false;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await WakilKurikulumService.getAbsensiGuru(
        page: _page, tanggal: _tanggalCtl.text, status: _status,
      );
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _tanggalCtl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal', border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  );
                  if (d != null) _tanggalCtl.text = d.toIso8601String().substring(0, 10);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                value: _status,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            ElevatedButton(onPressed: _load, child: const Text('Cari')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Tidak ada data')))
        else ...[
          DataTable(
            columns: const [
              DataColumn(label: Text('NIP')),
              DataColumn(label: Text('Nama Asatidz')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: _items.map((item) {
              final s = item as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(s['guru_nip']?.toString() ?? '')),
                DataCell(Text(s['guru_nama']?.toString() ?? '')),
                DataCell(Text(s['tanggal']?.toString() ?? '')),
                DataCell(_statusChip(s['status']?.toString() ?? '')),
                DataCell(Text(s['keterangan']?.toString() ?? '-')),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 ? () { _page--; _load(); } : null,
              ),
              Text('Halaman $_page dari $_totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'hadir': color = Colors.green; break;
      case 'izin': color = Colors.orange; break;
      case 'sakit': color = Colors.blue; break;
      case 'alpa': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TabSiswa extends StatefulWidget {
  const _TabSiswa();

  @override
  State<_TabSiswa> createState() => _TabSiswaState();
}

class _TabSiswaState extends State<_TabSiswa> {
  final _tanggalCtl = TextEditingController();
  String? _kelasId, _status;
  List<dynamic> _items = [], _kelas = [];
  bool _loading = false;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadKelas();
    _load();
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _kelas = data['kelas'] as List<dynamic>? ?? [];
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await WakilKurikulumService.getAbsensiSiswa(
        page: _page, kelasId: _kelasId, tanggal: _tanggalCtl.text, status: _status,
      );
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                value: _kelasId,
                items: _kelas.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['nama'] as String? ?? ''))).toList(),
                onChanged: (v) => setState(() => _kelasId = v),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _tanggalCtl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal', border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  );
                  if (d != null) _tanggalCtl.text = d.toIso8601String().substring(0, 10);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                value: _status,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            ElevatedButton(onPressed: _load, child: const Text('Cari')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Tidak ada data')))
        else ...[
          DataTable(
            columns: const [
              DataColumn(label: Text('NIS')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Mapel')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: _items.map((item) {
              final s = item as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(s['siswa_nis']?.toString() ?? '')),
                DataCell(Text(s['siswa_nama']?.toString() ?? '')),
                DataCell(Text(s['kelas_nama']?.toString() ?? '')),
                DataCell(Text(s['mapel_nama']?.toString() ?? '-')),
                DataCell(Text(s['tanggal']?.toString() ?? '')),
                DataCell(_statusChip(s['status']?.toString() ?? '')),
                DataCell(Text(s['keterangan']?.toString() ?? '-')),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 ? () { _page--; _load(); } : null,
              ),
              Text('Halaman $_page dari $_totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'hadir': color = Colors.green; break;
      case 'izin': color = Colors.orange; break;
      case 'sakit': color = Colors.blue; break;
      case 'alpa': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TabRekap extends StatefulWidget {
  const _TabRekap();

  @override
  State<_TabRekap> createState() => _TabRekapState();
}

class _TabRekapState extends State<_TabRekap> {
  final _tglMulaiCtl = TextEditingController();
  final _tglSelesaiCtl = TextEditingController();
  String? _kelasId;
  List<dynamic> _kelas = [];
  Map<String, dynamic>? _rekap;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  @override
  void dispose() {
    _tglMulaiCtl.dispose();
    _tglSelesaiCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _kelas = data['kelas'] as List<dynamic>? ?? [];
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _rekap = await WakilKurikulumService.getRekapAbsensi(
        tanggalMulai: _tglMulaiCtl.text,
        tanggalSelesai: _tglSelesaiCtl.text,
        kelasId: _kelasId,
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              child: TextField(
                controller: _tglMulaiCtl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Mulai', border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  );
                  if (d != null) _tglMulaiCtl.text = d.toIso8601String().substring(0, 10);
                },
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _tglSelesaiCtl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Selesai', border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  );
                  if (d != null) _tglSelesaiCtl.text = d.toIso8601String().substring(0, 10);
                },
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                value: _kelasId,
                items: _kelas.map((k) => DropdownMenuItem(value: k['id'].toString(), child: Text(k['nama'] as String? ?? ''))).toList(),
                onChanged: (v) => setState(() => _kelasId = v),
              ),
            ),
            ElevatedButton(onPressed: _load, child: const Text('Tampilkan')),
          ],
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_rekap == null)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Pilih filter dan klik Tampilkan')))
        else ...[
          Text('Rekap Absensi Santri', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildRekapTable(_rekap!['siswa'] as Map<String, dynamic>? ?? {}, _rekap!['total_siswa'] as int? ?? 0),
          const SizedBox(height: 24),
          Text('Rekap Absensi Asatidz', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildRekapTable(_rekap!['guru'] as Map<String, dynamic>? ?? {}, _rekap!['total_guru'] as int? ?? 0),
        ],
      ],
    );
  }

  Widget _buildRekapTable(Map<String, dynamic> data, int total) {
    final statuses = ['hadir', 'izin', 'sakit', 'alpa'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...statuses.map((s) {
              final count = data[s] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        backgroundColor: Colors.grey[200],
                        color: _statusColor(s),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$total', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
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
}
