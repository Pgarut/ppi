import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class RaporPage extends StatefulWidget {
  const RaporPage({super.key});

  @override
  State<RaporPage> createState() => _RaporPageState();
}

class _RaporPageState extends State<RaporPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_tabCtrl.index == 1) {
        final res = await AdminService.getArsipRapor(page: _page);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      } else {
        final res = await AdminService.getRapor(page: _page, statusKirim: _statusFilter.isEmpty ? null : _statusFilter);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      }
    } catch (_) { _data = []; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cetak(int id) async {
    try {
      await AdminService.cetakRapor(id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor dicetak dan diarsipkan'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cetak: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapor'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) { _page = 1; _load(); },
          tabs: const [Tab(text: 'Monitoring'), Tab(text: 'Arsip')],
        ),
      ),
      body: Column(children: [
        if (_tabCtrl.index == 0)
          Padding(padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _statusFilter.isEmpty ? null : _statusFilter,
                isDense: true, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), labelText: 'Status Kirim'),
                items: ['', 'draft', 'terkirim', 'divalidasi'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                    child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) { _statusFilter = v ?? ''; },
              )),
              const SizedBox(width: 8),
              IconButton(onPressed: () { _page = 1; _load(); }, icon: const Icon(Icons.search)),
            ]),
          ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data.isEmpty
                ? Center(child: Text('Tidak ada data rapor.', style: TextStyle(color: Colors.grey[500])))
                : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _data.length) {
                        if (_page >= _totalPages) return const SizedBox.shrink();
                        return TextButton(onPressed: () { _page++; _load(); }, child: const Text('Muat lebih banyak'));
                      }
                      final d = _data[i];
                      final isArsip = _tabCtrl.index == 1;
                      if (isArsip) {
                        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 18, backgroundColor: Colors.blueGrey,
                            child: Text((d['siswa_nama'] as String? ?? '?')[0], style: const TextStyle(color: Colors.white, fontSize: 13))),
                          title: Text(d['siswa_nama'] as String? ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${d['semester_nama'] ?? '-'} | ${d['dicetak_pada'] ?? '-'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ));
                      }
                      final statusKirim = d['status_kirim'] as String? ?? 'draft';
                      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 18,
                          backgroundColor: statusKirim == 'divalidasi' ? Colors.green : statusKirim == 'terkirim' ? Colors.blue : Colors.orange,
                          child: Text((d['siswa_nama'] as String? ?? '?')[0], style: const TextStyle(color: Colors.white, fontSize: 13))),
                        title: Text('${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${d['kelas_nama'] ?? '-'} | ${d['semester_nama'] ?? '-'} | Predikat: ${d['predikat'] ?? '-'}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusKirim == 'divalidasi' ? Colors.green.withOpacity(0.15) : statusKirim == 'terkirim' ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusKirim, style: TextStyle(fontSize: 11,
                                color: statusKirim == 'divalidasi' ? Colors.green : statusKirim == 'terkirim' ? Colors.blue : Colors.orange, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 4),
                          IconButton(icon: const Icon(Icons.print_outlined, size: 18, color: Colors.blueGrey),
                            onPressed: () => _cetak(d['id'] as int), tooltip: 'Cetak'),
                        ]),
                      ));
                    },
                  )),
      ]),
    );
  }
}
