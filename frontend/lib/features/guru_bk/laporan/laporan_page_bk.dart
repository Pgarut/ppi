import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class LaporanPageBK extends StatefulWidget {
  const LaporanPageBK({super.key});

  @override
  State<LaporanPageBK> createState() => _LaporanPageBKState();
}

class _LaporanPageBKState extends State<LaporanPageBK>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tab = 0;

  Map<String, dynamic>? _bulanan;
  List<dynamic> _rekap = [];
  List<dynamic> _laporanKonseling = [];
  List<dynamic> _laporanBakatMinat = [];
  List<dynamic> _laporanMonitoring = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        GuruBKService.getLaporanBulanan(),
        GuruBKService.getRekapKasus(),
        GuruBKService.getLaporanKonseling(),
        GuruBKService.getLaporanBakatMinat(),
        GuruBKService.getLaporanMonitoring(),
      ]);
      _bulanan = results[0] as Map<String, dynamic>?;
      _rekap = results[1] as List<dynamic>;
      _laporanKonseling = results[2] as List<dynamic>;
      _laporanBakatMinat = results[3] as List<dynamic>;
      _laporanMonitoring = results[4] as List<dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Text('Laporan BK', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month), text: 'Bulanan'),
                  Tab(icon: Icon(Icons.category), text: 'Rekap Kasus'),
                  Tab(icon: Icon(Icons.support_agent), text: 'Konseling'),
                  Tab(icon: Icon(Icons.psychology), text: 'Bakat-Minat'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Monitoring'),
                ],
              ),
              Expanded(
                child: _tab == 0
                    ? _buildBulanan()
                    : _tab == 1
                        ? _buildRekap()
                        : _tab == 2
                            ? _buildLaporanKonseling()
                            : _tab == 3
                                ? _buildLaporanBakatMinat()
                                : _buildLaporanMonitoring(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulanan() {
    final items = _bulanan?['items'] as List<dynamic>? ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (items.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data')))
        else
          DataTable(
            columns: const [
              DataColumn(label: Text('Periode')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('Baru')),
              DataColumn(label: Text('Diproses')),
              DataColumn(label: Text('Selesai')),
            ],
            rows: items.map((r) => DataRow(cells: [
              DataCell(Text(r['periode']?.toString() ?? '')),
              DataCell(Text('${r['total'] ?? 0}')),
              DataCell(Text('${r['baru'] ?? 0}')),
              DataCell(Text('${r['diproses'] ?? 0}')),
              DataCell(Text('${r['selesai'] ?? 0}')),
            ])).toList(),
          ),
      ],
    );
  }

  Widget _buildRekap() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _rekap.map((r) => Card(
        child: ListTile(
          leading: Icon(r['kategori'] == 'kasus' ? Icons.gavel : Icons.warning, color: Colors.red),
          title: Text(r['kategori']?.toString() ?? ''),
          subtitle: Text('Siswa terlibat: ${r['siswa_terlibat'] ?? 0}'),
          trailing: Text('${r['total'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
        ),
      )).toList(),
    );
  }

  Widget _buildLaporanKonseling() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _laporanKonseling.isEmpty
          ? [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data konseling')))]
          : _laporanKonseling.map((l) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.indigo),
                title: Text(l['siswa_nama']?.toString() ?? ''),
                subtitle: Text('${l['tanggal'] ?? ''} — ${l['jenis'] ?? ''}'),
                trailing: Text('${l['total'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
              ),
            )).toList(),
    );
  }

  Widget _buildLaporanBakatMinat() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _laporanBakatMinat.isEmpty
          ? [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data bakat-minat')))]
          : _laporanBakatMinat.map((l) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(l['jenis'] == 'bakat' ? Icons.star : Icons.favorite, color: Colors.indigo),
                title: Text(l['siswa_nama']?.toString() ?? ''),
                subtitle: Text('${l['jenis'] ?? ''} — ${l['deskripsi'] ?? ''}'),
                trailing: Text('${l['total'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
              ),
            )).toList(),
    );
  }

  Widget _buildLaporanMonitoring() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _laporanMonitoring.isEmpty
          ? [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data monitoring')))]
          : _laporanMonitoring.map((l) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.trending_up, color: Colors.indigo),
                title: Text(l['siswa_nama']?.toString() ?? ''),
                subtitle: Text(l['keterangan']?.toString() ?? ''),
                trailing: Text('${l['total'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
              ),
            )).toList(),
    );
  }
}
