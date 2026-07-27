import 'package:flutter/material.dart';
import '../services/guru_service.dart';

class WaliKelasPageGuru extends StatefulWidget {
  const WaliKelasPageGuru({super.key});

  @override
  State<WaliKelasPageGuru> createState() => _WaliKelasPageGuruState();
}

class _WaliKelasPageGuruState extends State<WaliKelasPageGuru> {
  Map<String, dynamic>? _dataSiswa;
  Map<String, dynamic>? _rekapAbsensi;
  Map<String, dynamic>? _rekapNilai;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        GuruService.getDataSiswa(),
        GuruService.getRekapAbsensi(),
        GuruService.getRekapNilai(),
      ]);
      _dataSiswa = results[0];
      _rekapAbsensi = results[1];
      _rekapNilai = results[2];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final kelas = _dataSiswa?['kelas'] as Map<String, dynamic>?;
    final siswa = _dataSiswa?['siswa'] as List<dynamic>? ?? [];
    final rekapAbs = _rekapAbsensi?['rekap'] as List<dynamic>? ?? [];
    final rekapNil = _rekapNilai?['rekap'] as List<dynamic>? ?? [];

    if (kelas == null) {
      return const Center(child: Text('Anda bukan wali kelas'));
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.teal.shade50,
          child: Text('Wali Kelas: ${kelas['nama']}', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.teal,
                  tabs: const [
                    Tab(icon: Icon(Icons.people), text: 'Data Siswa'),
                    Tab(icon: Icon(Icons.checklist), text: 'Rekap Absensi'),
                    Tab(icon: Icon(Icons.grading), text: 'Rekap Nilai'),
                  ],
                  onTap: (i) => setState(() => _tab = i),
                ),
                Expanded(
                  child: _tab == 0
                    ? _buildDataSiswa(siswa)
                    : _tab == 1
                      ? _buildRekapAbsensi(rekapAbs)
                      : _buildRekapNilai(rekapNil),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSiswa(List<dynamic> siswa) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DataTable(
          columns: const [
            DataColumn(label: Text('NIS')), DataColumn(label: Text('NISN')),
            DataColumn(label: Text('Nama')), DataColumn(label: Text('JK')),
            DataColumn(label: Text('Status')),
          ],
          rows: siswa.map((s) => DataRow(cells: [
            DataCell(Text(s['nis']?.toString() ?? '')),
            DataCell(Text(s['nisn']?.toString() ?? '-')),
            DataCell(Text(s['nama']?.toString() ?? '')),
            DataCell(Text(s['jenis_kelamin']?.toString() ?? '-')),
            DataCell(Text(s['status']?.toString() ?? '')),
          ])).toList(),
        ),
      ],
    );
  }

  Widget _buildRekapAbsensi(List<dynamic> rekap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rekap.map((r) => ListTile(
          leading: Icon(_iconAbsensi(r['status']?.toString() ?? ''), color: _colorAbsensi(r['status']?.toString() ?? '')),
          title: Text(r['status']?.toString() ?? ''),
          trailing: Text('${r['jumlah']} kali', style: Theme.of(context).textTheme.titleMedium),
        )).toList(),
      ),
    );
  }

  Widget _buildRekapNilai(List<dynamic> rekap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rekap.map((r) => ListTile(
          title: Text(r['jenis']?.toString() ?? ''),
          subtitle: Text('Total: ${r['total']} · Rata-rata: ${r['rata_rata']}'),
        )).toList(),
      ),
    );
  }

  IconData _iconAbsensi(String s) {
    switch (s) {
      case 'hadir': return Icons.check_circle;
      case 'izin': return Icons.info;
      case 'sakit': return Icons.local_hospital;
      case 'alpa': return Icons.cancel;
      default: return Icons.help;
    }
  }

  Color _colorAbsensi(String s) {
    switch (s) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }
}
