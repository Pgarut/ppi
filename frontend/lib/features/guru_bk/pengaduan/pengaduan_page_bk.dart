import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class PengaduanPageBK extends StatefulWidget {
  const PengaduanPageBK({super.key});

  @override
  State<PengaduanPageBK> createState() => _PengaduanPageBKState();
}

class _PengaduanPageBKState extends State<PengaduanPageBK> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await GuruBKService.getPengaduan(status: _filterStatus);
      _items = data['items'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _updateStatus(int id, String status) async {
    final tindakLanjut = status == 'selesai' || status == 'ditutup'
      ? await showDialog<String>(context: context, builder: (ctx) {
          final ctl = TextEditingController();
          return AlertDialog(
            title: const Text('Tindak Lanjut'),
            content: TextField(controller: ctl, maxLines: 3, decoration: const InputDecoration(hintText: 'Catatan tindak lanjut...', border: OutlineInputBorder())),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Simpan')),
            ],
          );
        })
      : null;

    try {
      await GuruBKService.updatePengaduan(id, {
        'status': status,
        if (tindakLanjut != null && tindakLanjut.isNotEmpty) 'tindak_lanjut': tindakLanjut,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status diperbarui'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Daftar Pengaduan', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            FilterChip(label: const Text('Semua'), selected: _filterStatus == null, onSelected: (_) { setState(() => _filterStatus = null); _load(); }),
            FilterChip(label: const Text('Baru'), selected: _filterStatus == 'baru', onSelected: (_) { setState(() => _filterStatus = 'baru'); _load(); }),
            FilterChip(label: const Text('Diproses'), selected: _filterStatus == 'diproses', onSelected: (_) { setState(() => _filterStatus = 'diproses'); _load(); }),
            FilterChip(label: const Text('Selesai'), selected: _filterStatus == 'selesai', onSelected: (_) { setState(() => _filterStatus = 'selesai'); _load(); }),
            FilterChip(label: const Text('Ditutup'), selected: _filterStatus == 'ditutup', onSelected: (_) { setState(() => _filterStatus = 'ditutup'); _load(); }),
            const SizedBox(width: 16),
            ElevatedButton.icon(icon: const Icon(Icons.refresh), onPressed: _load, label: const Text('Refresh')),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && _items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Tidak ada pengaduan'))),
        ..._items.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: Icon(_iconStatus(p['status']?.toString() ?? ''), color: _colorStatus(p['status']?.toString() ?? '')),
            title: Text(p['deskripsi']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text('${p['siswa_nama'] ?? '?'} — ${p['kategori'] ?? ''}'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NIS: ${p['siswa_nis'] ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                    Text('Pelapor: ${p['pelapor_nama'] ?? '-'}', style: Theme.of(context).textTheme.bodySmall),
                    Text('Status: ${p['status'] ?? '-'}'),
                    if (p['tindak_lanjut'] != null) Text('Tindak Lanjut: ${p['tindak_lanjut']}', style: Theme.of(context).textTheme.bodySmall),
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (p['status'] == 'baru')
                          ActionChip(label: const Text('Proses'), avatar: const Icon(Icons.engineering, size: 16), onPressed: () => _updateStatus(p['id'], 'diproses')),
                        if (p['status'] == 'diproses' || p['status'] == 'baru')
                          ActionChip(label: const Text('Selesai'), avatar: const Icon(Icons.check, size: 16), onPressed: () => _updateStatus(p['id'], 'selesai')),
                        if (p['status'] != 'ditutup')
                          ActionChip(label: const Text('Tutup'), avatar: const Icon(Icons.close, size: 16), onPressed: () => _updateStatus(p['id'], 'ditutup')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _iconStatus(String s) {
    switch (s) {
      case 'baru': return Icons.fiber_new;
      case 'diproses': return Icons.engineering;
      case 'selesai': return Icons.check_circle;
      case 'ditutup': return Icons.cancel;
      default: return Icons.help;
    }
  }

  Color _colorStatus(String s) {
    switch (s) {
      case 'baru': return Colors.red;
      case 'diproses': return Colors.orange;
      case 'selesai': return Colors.green;
      case 'ditutup': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
