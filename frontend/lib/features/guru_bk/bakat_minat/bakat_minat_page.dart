import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class BakatMinatPage extends StatefulWidget {
  const BakatMinatPage({super.key});

  @override
  State<BakatMinatPage> createState() => _BakatMinatPageState();
}

class _BakatMinatPageState extends State<BakatMinatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tab = 0;

  List<dynamic> _items = [];
  bool _loading = true;
  String? _filterJenis;

  List<dynamic> _siswaList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      _items = await GuruBKService.getBakatMinat(jenis: _filterJenis);
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
          child: Text('Bakat & Minat', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: 'Data'),
                  Tab(icon: Icon(Icons.add_circle_outline), text: 'Tambah'),
                ],
              ),
              Expanded(child: _tab == 0 ? _buildData() : _buildForm()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildData() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(label: const Text('Semua'), selected: _filterJenis == null, onSelected: (_) {
                setState(() => _filterJenis = null);
                _load();
              }),
              FilterChip(label: const Text('Bakat'), selected: _filterJenis == 'bakat', onSelected: (_) {
                setState(() => _filterJenis = 'bakat');
                _load();
              }),
              FilterChip(label: const Text('Minat'), selected: _filterJenis == 'minat', onSelected: (_) {
                setState(() => _filterJenis = 'minat');
                _load();
              }),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data')))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _items.map((i) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: Icon(i['jenis'] == 'bakat' ? Icons.star : Icons.favorite, color: Colors.indigo),
                          title: Text(i['siswa_nama']?.toString() ?? ''),
                          subtitle: Text('${i['jenis'] ?? ''} — ${i['deskripsi']?.toString() ?? ''}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deskripsi: ${i['deskripsi'] ?? '-'}'),
                                  const SizedBox(height: 4),
                                  Text('Catatan Pengembangan: ${i['catatan_pengembangan'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(i)),
                                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(i['id'])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final deskripsiCtl = TextEditingController();
    final catatanCtl = TextEditingController();
    String? selectedSiswaId;
    String selectedJenis = 'bakat';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tambah Data Baru', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _siswaList.isEmpty ? GuruBKService.getSiswaList().then((v) {
            _siswaList = v;
            return v;
          }) : Future.value(_siswaList),
          builder: (ctx, snap) {
            final siswa = snap.data ?? _siswaList;
            return DropdownButtonFormField<String>(
              value: selectedSiswaId,
              decoration: const InputDecoration(labelText: 'Siswa', border: OutlineInputBorder()),
              items: siswa.map((s) => DropdownMenuItem(
                value: s['id'].toString(),
                child: Text(s['nama']?.toString() ?? ''),
              )).toList(),
              onChanged: (v) => selectedSiswaId = v,
            );
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedJenis,
          decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
          items: ['bakat', 'minat'].map((j) => DropdownMenuItem(value: j, child: Text(j == 'bakat' ? 'Bakat' : 'Minat'))).toList(),
          onChanged: (v) => selectedJenis = v!,
        ),
        const SizedBox(height: 12),
        TextField(controller: deskripsiCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: catatanCtl, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan Pengembangan', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          onPressed: () async {
            try {
              await GuruBKService.createBakatMinat({
                'siswa_id': int.tryParse(selectedSiswaId ?? ''),
                'jenis': selectedJenis,
                'deskripsi': deskripsiCtl.text,
                'catatan_pengembangan': catatanCtl.text,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data disimpan'), backgroundColor: Colors.green));
                _load();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
              }
            }
          },
          label: const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _showForm(Map<String, dynamic> edit) async {
    final deskripsiCtl = TextEditingController(text: edit['deskripsi']?.toString() ?? '');
    final catatanCtl = TextEditingController(text: edit['catatan_pengembangan']?.toString() ?? '');
    String? selectedSiswaId = edit['siswa_id']?.toString();
    String selectedJenis = edit['jenis']?.toString() ?? 'bakat';

    if (_siswaList.isEmpty) {
      try {
        _siswaList = await GuruBKService.getSiswaList();
      } catch (_) {}
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? siswaId = selectedSiswaId;
        String jenis = selectedJenis;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Edit Data'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: siswaId,
                    decoration: const InputDecoration(labelText: 'Siswa', border: OutlineInputBorder()),
                    items: _siswaList.map((s) => DropdownMenuItem(
                      value: s['id'].toString(),
                      child: Text(s['nama']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => siswaId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: jenis,
                    decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
                    items: ['bakat', 'minat'].map((j) => DropdownMenuItem(value: j, child: Text(j == 'bakat' ? 'Bakat' : 'Minat'))).toList(),
                    onChanged: (v) => setDialogState(() => jenis = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: deskripsiCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: catatanCtl, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan Pengembangan', border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              TextButton(onPressed: () async {
                try {
                  await GuruBKService.updateBakatMinat(edit['id'], {
                    'siswa_id': int.tryParse(siswaId ?? ''),
                    'jenis': jenis,
                    'deskripsi': deskripsiCtl.text,
                    'catatan_pengembangan': catatanCtl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
                  }
                }
              }, child: const Text('Simpan')),
            ],
          ),
        );
      },
    );
    if (result == true) _load();
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Data'),
      content: const Text('Yakin ingin menghapus?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      try {
        await GuruBKService.deleteBakatMinat(id);
        _load();
      } catch (_) {}
    }
  }
}
