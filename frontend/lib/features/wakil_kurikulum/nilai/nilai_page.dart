import 'package:flutter/material.dart';
import '../services/wakil_kurikulum_service.dart';

class NilaiPageWK extends StatefulWidget {
  const NilaiPageWK({super.key});

  @override
  State<NilaiPageWK> createState() => _NilaiPageWKState();
}

class _NilaiPageWKState extends State<NilaiPageWK> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _bobot = [];
  List<Map<String, dynamic>> _monitoring = [];
  List<Map<String, dynamic>> _status = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _bobot = (await WakilKurikulumService.getBobotNilai()).cast<Map<String, dynamic>>();
      _monitoring = (await WakilKurikulumService.getMonitoringNilai()).cast<Map<String, dynamic>>();
      _status = (await WakilKurikulumService.getStatusPengumpulan()).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Bobot Nilai'), Tab(text: 'Monitoring'), Tab(text: 'Status Pengumpulan'),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildBobotTab(),
              _buildMonitoringTab(),
              _buildStatusTab(),
            ]),
    );
  }

  Widget _buildBobotTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _showFormBobot, icon: const Icon(Icons.add, size: 18), label: const Text('Atur Bobot')),
        ]),
      ),
      Expanded(child: _bobot.isEmpty
          ? Center(child: Text('Belum ada bobot nilai.', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _bobot.length,
              itemBuilder: (_, i) {
                final b = _bobot[i];
                return Card(child: ListTile(
                  title: Text('Mapel: ${b['mapel_nama'] ?? 'Default'}'),
                  subtitle: Text('Harian: ${b['harian_persen']}% | Tugas: ${b['tugas_persen']}% | UTS: ${b['uts_persen']}% | UAS: ${b['uas_persen']}%'),
                ));
              },
            )),
    ]);
  }

  Future<void> _showFormBobot() async {
    final mapelCtrl = TextEditingController();
    final thnAjaranCtrl = TextEditingController();
    final harianCtrl = TextEditingController(text: '20');
    final tugasCtrl = TextEditingController(text: '20');
    final utsCtrl = TextEditingController(text: '30');
    final uasCtrl = TextEditingController(text: '30');

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Bobot Nilai'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran ID (kosongkan untuk default)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: thnAjaranCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tahun Ajaran ID *', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: harianCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harian (%)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: tugasCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tugas (%)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: utsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UTS (%)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: uasCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UAS (%)', border: OutlineInputBorder())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            try {
              await WakilKurikulumService.createBobotNilai({
                'mata_pelajaran_id': int.tryParse(mapelCtrl.text),
                'tahun_ajaran_id': int.tryParse(thnAjaranCtrl.text),
                'harian_persen': int.tryParse(harianCtrl.text) ?? 20,
                'tugas_persen': int.tryParse(tugasCtrl.text) ?? 20,
                'uts_persen': int.tryParse(utsCtrl.text) ?? 30,
                'uas_persen': int.tryParse(uasCtrl.text) ?? 30,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab() {
    if (_monitoring.isEmpty) return Center(child: Text('Belum ada data nilai.', style: TextStyle(color: Colors.grey[500])));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _monitoring.length,
      itemBuilder: (_, i) {
        final n = _monitoring[i];
        return Card(child: ListTile(
          title: Text('${n['siswa_nama'] ?? '-'} | ${n['mapel_nama'] ?? '-'}'),
          subtitle: Text('Nilai: ${n['nilai']} | ${n['jenis']} | ${n['status_validasi']}'),
        ));
      },
    );
  }

  Widget _buildStatusTab() {
    if (_status.isEmpty) return Center(child: Text('Belum ada data.', style: TextStyle(color: Colors.grey[500])));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _status.length,
      itemBuilder: (_, i) {
        final s = _status[i];
        return Card(child: ListTile(
          title: Text(s['guru_nama']?.toString() ?? '-'),
          subtitle: Text('Input: ${s['total_input']} | Draft: ${s['draft']} | Tervalidasi: ${s['tervalidasi']}'),
          trailing: Text('${s['tervalidasi']}/${s['total_input']}',
              style: TextStyle(fontWeight: FontWeight.bold, color: (s['draft'] ?? 0) > 0 ? Colors.orange : Colors.green)),
        ));
      },
    );
  }
}
