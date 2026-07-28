import 'package:flutter/material.dart';
import '../services/wakil_kurikulum_service.dart';

class LaporanPageWK extends StatefulWidget {
  const LaporanPageWK({super.key});

  @override
  State<LaporanPageWK> createState() => _LaporanPageWKState();
}

class _LaporanPageWKState extends State<LaporanPageWK> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  String _jenis = 'jadwal';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await WakilKurikulumService.getLaporan(_jenis);
      _data = res.cast<Map<String, dynamic>>();
    } catch (_) { _data = []; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) {
          _jenis = ['jadwal', 'absensi', 'nilai', 'rapor'][i];
          _load();
        }, tabs: const [
          Tab(text: 'Jadwal'), Tab(text: 'Absensi'), Tab(text: 'Nilai'), Tab(text: 'Rapor'),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _data.length,
                  itemBuilder: (_, i) {
                    final d = _data[i];
                    return Card(child: ListTile(
                      title: Text(_formatTitle(d), style: const TextStyle(fontSize: 13)),
                      subtitle: Text(_formatSubtitle(d), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ));
                  },
                ),
    );
  }

  String _formatTitle(Map<String, dynamic> d) {
    switch (_jenis) {
      case 'jadwal': return '${d['hari'] ?? '-'} | ${d['jam_mulai'] ?? '-'}-${d['jam_selesai'] ?? '-'} | ${d['mapel'] ?? '-'}';
      case 'absensi': return '${d['siswa_nama'] ?? '-'} | ${d['status'] ?? '-'}';
      case 'nilai': return '${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'} | ${d['nilai'] ?? ''}';
      case 'rapor': return '${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'} | ${d['nilai_akhir'] ?? ''}';
      default: return '-';
    }
  }

  String _formatSubtitle(Map<String, dynamic> d) {
    switch (_jenis) {
      case 'jadwal': return 'Asatidz: ${d['guru'] ?? '-'} | Kelas: ${d['kelas'] ?? '-'} | Ruang: ${d['ruangan'] ?? '-'}';
      case 'absensi': return 'Kelas: ${d['kelas_nama'] ?? '-'} | Tgl: ${d['tanggal'] ?? '-'}';
      case 'nilai': return 'Kelas: ${d['kelas_nama'] ?? '-'} | ${d['jenis'] ?? '-'} | ${d['status_validasi'] ?? '-'}';
      case 'rapor': return 'Kelas: ${d['kelas_nama'] ?? '-'} | ${d['predikat'] ?? ''} | ${d['status_kirim'] ?? '-'}';
      default: return '-';
    }
  }
}
