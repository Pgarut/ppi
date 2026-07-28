import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class MonitoringAkademikPage extends StatefulWidget {
  const MonitoringAkademikPage({super.key});

  @override
  State<MonitoringAkademikPage> createState() => _MonitoringAkademikPageState();
}

class _MonitoringAkademikPageState extends State<MonitoringAkademikPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tab = 0;

  List<dynamic> _nilai = [];
  List<dynamic> _absensi = [];
  List<dynamic> _pelanggaran = [];
  bool _loading = true;

  int? _filterSiswaId;
  int? _filterKelasId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        GuruBKService.getMonitoringNilai(siswaId: _filterSiswaId, kelasId: _filterKelasId),
        GuruBKService.getMonitoringAbsensi(siswaId: _filterSiswaId, kelasId: _filterKelasId),
        GuruBKService.getMonitoringPelanggaran(),
      ]);
      _nilai = results[0];
      _absensi = results[1];
      _pelanggaran = results[2];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Text('Monitoring Akademik', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                tabs: const [
                  Tab(icon: Icon(Icons.grade), text: 'Nilai'),
                  Tab(icon: Icon(Icons.event_busy), text: 'Absensi'),
                  Tab(icon: Icon(Icons.warning), text: 'Pelanggaran'),
                ],
              ),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(child: _tab == 0 ? _buildNilai() : _tab == 1 ? _buildAbsensi() : _buildPelanggaran()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNilai() {
    if (_nilai.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data nilai')));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Santri')),
            DataColumn(label: Text('Jenis')),
            DataColumn(label: Text('Rata-rata')),
          ],
          rows: _nilai.map((n) => DataRow(cells: [
            DataCell(Text(n['siswa_nama']?.toString() ?? '')),
            DataCell(Text(n['jenis']?.toString() ?? '')),
            DataCell(Text('${n['rata_rata'] ?? 0}')),
          ])).toList(),
        ),
      ],
    );
  }

  Widget _buildAbsensi() {
    if (_absensi.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data absensi')));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('Santri')),
            DataColumn(label: Text('Hadir')),
            DataColumn(label: Text('Sakit')),
            DataColumn(label: Text('Izin')),
            DataColumn(label: Text('Alpha')),
          ],
          rows: _absensi.map((a) => DataRow(cells: [
            DataCell(Text(a['siswa_nama']?.toString() ?? '')),
            DataCell(Text('${a['hadir'] ?? 0}')),
            DataCell(Text('${a['sakit'] ?? 0}')),
            DataCell(Text('${a['izin'] ?? 0}')),
            DataCell(Text('${a['alpha'] ?? 0}')),
          ])).toList(),
        ),
      ],
    );
  }

  Widget _buildPelanggaran() {
    if (_pelanggaran.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data pelanggaran')));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _pelanggaran.map((p) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.gavel, color: Colors.red.shade700),
          title: Text(p['siswa_nama']?.toString() ?? ''),
          subtitle: Text('${p['jenis'] ?? ''} — ${p['deskripsi']?.toString() ?? ''}'),
          trailing: Text('${p['total'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
        ),
      )).toList(),
    );
  }
}
