import 'package:flutter/material.dart';
import '../services/guru_service.dart';

class JadwalPageGuru extends StatefulWidget {
  const JadwalPageGuru({super.key});

  @override
  State<JadwalPageGuru> createState() => _JadwalPageGuruState();
}

class _JadwalPageGuruState extends State<JadwalPageGuru> {
  List<dynamic> _jadwal = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _error = null;
    try {
      _jadwal = await GuruService.getJadwal();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jadwal Mengajar', style: Theme.of(context).textTheme.headlineSmall),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Gagal memuat jadwal', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
              ],
            ),
          )
        else if (_jadwal.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada jadwal mengajar')))
        else
          ..._jadwal.map((item) {
            final j = item as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: Colors.green[700], size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            j['mata_pelajaran_nama']?.toString() ?? j['mapel_nama']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${j['hari']} | ${j['jam_mulai'] ?? '-'} - ${j['jam_selesai'] ?? '-'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          Text(
                            'Kelas: ${j['kelas_nama'] ?? '-'} | Ruang: ${j['ruangan_nama'] ?? j['ruangan'] ?? '-'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
