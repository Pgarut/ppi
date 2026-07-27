import 'package:flutter/material.dart';
import '../services/kepala_sekolah_service.dart';

class AbsensiPageKS extends StatefulWidget {
  const AbsensiPageKS({super.key});

  @override
  State<AbsensiPageKS> createState() => _AbsensiPageKSState();
}

class _AbsensiPageKSState extends State<AbsensiPageKS> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getAbsensi();
      _data = data['data'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Belum ada data absensi'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (ctx, i) {
        final d = _data[i] as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: Icon(
              d['status'] == 'hadir' ? Icons.check_circle : Icons.cancel,
              color: d['status'] == 'hadir' ? Colors.green : Colors.red,
            ),
            title: Text('${d['status'] ?? '-'} (${d['jumlah'] ?? 0})'),
            subtitle: Text('${d['kelas_nama'] ?? '-'} - ${d['periode'] ?? ''}'),
          ),
        );
      },
    );
  }
}
