import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class KonselingPage extends StatefulWidget {
  const KonselingPage({super.key});

  @override
  State<KonselingPage> createState() => _KonselingPageState();
}

class _KonselingPageState extends State<KonselingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tab = 0;

  // Jadwal
  List<dynamic> _jadwal = [];
  bool _jadwalLoading = true;

  // Catatan
  List<dynamic> _catatan = [];
  bool _catatanLoading = true;

  // untuk dropdown siswa (cached list)
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
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadJadwal(), _loadCatatan()]);
  }

  Future<void> _loadJadwal() async {
    setState(() => _jadwalLoading = true);
    try {
      final data = await GuruBKService.getJadwalKonseling();
      _jadwal = data['items'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _jadwalLoading = false);
  }

  Future<void> _loadCatatan() async {
    setState(() => _catatanLoading = true);
    try {
      final data = await GuruBKService.getKonseling();
      _catatan = data['items'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _catatanLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.indigo.shade50,
          child: Text('Konseling', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month), text: 'Jadwal'),
                  Tab(icon: Icon(Icons.notes), text: 'Catatan'),
                ],
              ),
              Expanded(child: _tab == 0 ? _buildJadwal() : _buildCatatan()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Jadwal Tab ──

  Widget _buildJadwal() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            onPressed: _showFormJadwal,
            label: const Text('Tambah Jadwal'),
          ),
        ),
        Expanded(
          child: _jadwalLoading
              ? const Center(child: CircularProgressIndicator())
              : _jadwal.isEmpty
                  ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada jadwal')))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _jadwal.map((j) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(Icons.event, color: Colors.indigo),
                          title: Text(j['siswa_nama']?.toString() ?? ''),
                          subtitle: Text('${j['tanggal'] ?? ''} — ${j['jam'] ?? ''} (${j['jenis'] ?? ''})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showFormJadwal(j)),
                              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteJadwal(j['id'])),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
        ),
      ],
    );
  }

  Future<void> _showFormJadwal([Map<String, dynamic>? edit]) async {
    final tanggalCtl = TextEditingController(text: edit?['tanggal']?.toString() ?? '');
    final jamCtl = TextEditingController(text: edit?['jam']?.toString() ?? '');
    String? selectedSiswaId = edit?['siswa_id']?.toString();
    String? selectedJenis = edit?['jenis']?.toString() ?? 'individu';

    if (_siswaList.isEmpty) {
      try {
        _siswaList = await GuruBKService.getSiswaList();
      } catch (_) {}
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? siswaId = selectedSiswaId;
        String jenis = selectedJenis!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(edit != null ? 'Edit Jadwal' : 'Tambah Jadwal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: siswaId,
                    decoration: const InputDecoration(labelText: 'Santri', border: OutlineInputBorder()),
                    items: _siswaList.map((s) => DropdownMenuItem(
                      value: s['id'].toString(),
                      child: Text(s['nama']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => siswaId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: tanggalCtl, decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: jamCtl, decoration: const InputDecoration(labelText: 'Jam (HH:MM)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: jenis,
                    decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
                    items: ['individu', 'kelompok', 'konsultasi'].map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                    onChanged: (v) => setDialogState(() => jenis = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              TextButton(onPressed: () async {
                final body = {
                  'siswa_id': int.tryParse(siswaId ?? ''),
                  'tanggal': tanggalCtl.text,
                  'jam': jamCtl.text,
                  'jenis': jenis,
                };
                try {
                  if (edit != null) {
                    await GuruBKService.updateJadwalKonseling(edit['id'], body);
                  } else {
                    await GuruBKService.createJadwalKonseling(body);
                  }
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
    if (result == true) _loadJadwal();
  }

  Future<void> _deleteJadwal(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Hapus Jadwal'),
      content: const Text('Yakin ingin menghapus?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) {
      try {
        await GuruBKService.deleteJadwalKonseling(id);
        _loadJadwal();
      } catch (_) {}
    }
  }

  // ── Catatan Tab ──

  Widget _buildCatatan() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            onPressed: _showFormCatatan,
            label: const Text('Tambah Catatan'),
          ),
        ),
        Expanded(
          child: _catatanLoading
              ? const Center(child: CircularProgressIndicator())
              : _catatan.isEmpty
                  ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada catatan')))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _catatan.map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(Icons.notes, color: Colors.indigo),
                          title: Text(c['siswa_nama']?.toString() ?? ''),
                          subtitle: Text(c['tanggal']?.toString() ?? ''),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Catatan: ${c['catatan'] ?? '-'}'),
                                  const SizedBox(height: 4),
                                  Text('Tindak Lanjut: ${c['tindak_lanjut'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showFormCatatan(c)),
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

  Future<void> _showFormCatatan([Map<String, dynamic>? edit]) async {
    final tanggalCtl = TextEditingController(text: edit?['tanggal']?.toString() ?? '');
    final catatanCtl = TextEditingController(text: edit?['catatan']?.toString() ?? '');
    final tindakLanjutCtl = TextEditingController(text: edit?['tindak_lanjut']?.toString() ?? '');
    String? selectedSiswaId = edit?['siswa_id']?.toString();

    if (_siswaList.isEmpty) {
      try {
        _siswaList = await GuruBKService.getSiswaList();
      } catch (_) {}
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? siswaId = selectedSiswaId;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(edit != null ? 'Edit Catatan' : 'Tambah Catatan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: siswaId,
                    decoration: const InputDecoration(labelText: 'Santri', border: OutlineInputBorder()),
                    items: _siswaList.map((s) => DropdownMenuItem(
                      value: s['id'].toString(),
                      child: Text(s['nama']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => siswaId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: tanggalCtl, decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: catatanCtl, maxLines: 3, decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: tindakLanjutCtl, maxLines: 2, decoration: const InputDecoration(labelText: 'Tindak Lanjut', border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              TextButton(onPressed: () async {
                final body = {
                  'siswa_id': int.tryParse(siswaId ?? ''),
                  'tanggal': tanggalCtl.text,
                  'catatan': catatanCtl.text,
                  'tindak_lanjut': tindakLanjutCtl.text,
                };
                try {
                  if (edit != null) {
                    await GuruBKService.updateKonseling(edit['id'], body);
                  } else {
                    await GuruBKService.createKonseling(body);
                  }
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
    if (result == true) _loadCatatan();
  }
}
