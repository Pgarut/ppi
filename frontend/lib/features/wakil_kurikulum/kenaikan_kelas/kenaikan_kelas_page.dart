import 'package:flutter/material.dart';
import '../services/wakil_kurikulum_service.dart';

class KenaikanKelasPage extends StatefulWidget {
  const KenaikanKelasPage({super.key});

  @override
  State<KenaikanKelasPage> createState() => _KenaikanKelasPageState();
}

class _KenaikanKelasPageState extends State<KenaikanKelasPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _kenaikan = [];
  List<Map<String, dynamic>> _alumni = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _kenaikan = (await WakilKurikulumService.getKenaikanKelas()).cast<Map<String, dynamic>>();
      _alumni = (await WakilKurikulumService.getAlumni()).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showProsesForm() async {
    final siswaIdCtrl = TextEditingController();
    final dariKelasCtrl = TextEditingController();
    final keKelasCtrl = TextEditingController();
    final thnAjaranCtrl = TextEditingController();
    String status = 'naik';

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Proses Kenaikan Kelas'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: siswaIdCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Santri ID', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: dariKelasCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dari Kelas ID', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: keKelasCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ke Kelas ID (kosong jika lulus)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: thnAjaranCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tahun Ajaran ID', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: const ['naik', 'tidak_naik', 'lulus'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { status = v ?? 'naik'; setD(() {}); },
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await WakilKurikulumService.prosesKenaikan({
                  'siswa_id': int.tryParse(siswaIdCtrl.text),
                  'dari_kelas_id': int.tryParse(dariKelasCtrl.text),
                  'ke_kelas_id': int.tryParse(keKelasCtrl.text),
                  'tahun_ajaran_id': int.tryParse(thnAjaranCtrl.text),
                  'status': status,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
            }, child: const Text('Proses')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kenaikan Kelas & Alumni'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Kenaikan Kelas'), Tab(text: 'Alumni'),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildKenaikanTab(),
              _buildAlumniTab(),
            ]),
    );
  }

  Widget _buildKenaikanTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _showProsesForm, icon: const Icon(Icons.trending_up, size: 18), label: const Text('Proses Kenaikan')),
        ]),
      ),
      Expanded(child: _kenaikan.isEmpty
          ? Center(child: Text('Belum ada data kenaikan.', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kenaikan.length,
              itemBuilder: (_, i) {
                final k = _kenaikan[i];
                return Card(child: ListTile(
                  title: Text(k['siswa_nama']?.toString() ?? '-'),
                  subtitle: Text('${k['dari_kelas'] ?? '-'} → ${k['status'] == 'lulus' ? 'LULUS' : (k['ke_kelas'] ?? '-')} | Status: ${k['status']}'),
                ));
              },
            )),
    ]);
  }

  Widget _buildAlumniTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _showFormAlumni, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Alumni')),
        ]),
      ),
      Expanded(child: _alumni.isEmpty
          ? Center(child: Text('Belum ada data alumni.', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _alumni.length,
              itemBuilder: (_, i) {
                final a = _alumni[i];
                return Card(child: ListTile(
                  title: Text(a['siswa_nama']?.toString() ?? '-'),
                  subtitle: Text('NIS: ${a['nis'] ?? '-'} | Lulus: ${a['tahun_lulus'] ?? '-'}'),
                ));
              },
            )),
    ]);
  }

  Future<void> _showFormAlumni() async {
    final siswaIdCtrl = TextEditingController();
    final tahunLulusCtrl = TextEditingController();
    final kontakCtrl = TextEditingController();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Alumni'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: siswaIdCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Santri ID', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: tahunLulusCtrl, decoration: const InputDecoration(labelText: 'Tahun Lulus', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: kontakCtrl, decoration: const InputDecoration(labelText: 'Kontak', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            try {
              await WakilKurikulumService.createAlumni({
                'siswa_id': int.tryParse(siswaIdCtrl.text),
                'tahun_lulus': tahunLulusCtrl.text,
                'kontak': kontakCtrl.text,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
