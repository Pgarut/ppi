import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../services/guru_service.dart';

class PengaduanPageGuru extends StatefulWidget {
  const PengaduanPageGuru({super.key});

  @override
  State<PengaduanPageGuru> createState() => _PengaduanPageGuruState();
}

class _PengaduanPageGuruState extends State<PengaduanPageGuru> {
  int? _siswaId;
  String _kategori = 'perilaku';
  final _deskripsiCtl = TextEditingController();
  final _buktiCtl = TextEditingController();
  List<dynamic> _siswa = [];
  List<dynamic> _pengaduanList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _siswa = data['siswa'] as List<dynamic>? ?? [];
      final p = await GuruService.getPengaduan();
      _pengaduanList = p['items'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _kirim() async {
    if (_siswaId == null || _deskripsiCtl.text.isEmpty) return;
    try {
      await GuruService.createPengaduan({
        'siswa_id': _siswaId,
        'kategori': _kategori,
        'deskripsi': _deskripsiCtl.text,
        'bukti_url': _buktiCtl.text.isNotEmpty ? _buktiCtl.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaduan terkirim'), backgroundColor: Colors.green));
        _deskripsiCtl.clear();
        _buktiCtl.clear();
      }
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _deskripsiCtl.dispose();
    _buktiCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pengaduan Santri', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporan Baru', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16, runSpacing: 12,
                  children: [
                    SizedBox(width: 250, child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Santri', border: OutlineInputBorder()),
                      items: _siswa.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text('${s['nis']} - ${s['nama']}'))).toList(),
                      onChanged: (v) => setState(() => _siswaId = v),
                    )),
                    SizedBox(width: 150, child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                      value: _kategori,
                      items: const [
                        DropdownMenuItem(value: 'perilaku', child: Text('Perilaku')),
                        DropdownMenuItem(value: 'kasus', child: Text('Kasus')),
                      ],
                      onChanged: (v) => setState(() => _kategori = v!),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deskripsiCtl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buktiCtl,
                  decoration: const InputDecoration(labelText: 'URL Bukti (opsional)', border: OutlineInputBorder(), hintText: 'https://...'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _kirim,
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim Laporan'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Riwayat Laporan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...(_pengaduanList.isEmpty
          ? [const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada laporan'))) ]
          : _pengaduanList.map((p) => Card(
              child: ListTile(
                leading: Icon(p['kategori'] == 'kasus' ? Icons.gavel : Icons.warning, color: Colors.red),
                title: Text(p['deskripsi']?.toString() ?? ''),
                subtitle: Text('${p['siswa_nama'] ?? '?'} — Status: ${p['status'] ?? 'baru'}'),
                trailing: Chip(label: Text(p['kategori']?.toString() ?? '')),
              ),
            )).toList()),
      ],
    );
  }
}


