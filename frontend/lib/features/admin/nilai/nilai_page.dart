import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class NilaiPage extends StatefulWidget {
  const NilaiPage({super.key});

  @override
  State<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _statusFilter = '';

  final _jenisTabs = [
    'Semua', 'Harian', 'Tugas', 'UTS', 'UAS', 'Akhir',
  ];

  String get _jenisValue {
    final idx = _tabCtrl.index;
    if (idx == 0) return '';
    return _jenisTabs[idx].toLowerCase();
  }

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: _jenisTabs.length, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getNilai(page: _page, jenis: _jenisValue.isEmpty ? null : _jenisValue,
          statusValidasi: _statusFilter.isEmpty ? null : _statusFilter);
      _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      _totalPages = res['pagination']?['total_pages'] ?? 1;
    } catch (_) { _data = []; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _validasi(int id) async {
    try {
      await AdminService.validasiNilai(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal validasi: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, isScrollable: true, onTap: (i) { _page = 1; _load(); },
          tabs: _jenisTabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              isDense: true, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), labelText: 'Status'),
              items: ['', 'draft', 'tervalidasi'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
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
                ? Center(child: Text('Tidak ada data nilai.', style: TextStyle(color: Colors.grey[500])))
                : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _data.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _data.length) {
                        if (_page >= _totalPages) return const SizedBox.shrink();
                        return TextButton(onPressed: () { _page++; _load(); }, child: const Text('Muat lebih banyak'));
                      }
                      final d = _data[i];
                      final statusValidasi = d['status_validasi'] as String? ?? 'draft';
                      final isDraft = statusValidasi == 'draft';
                      return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 18, backgroundColor: isDraft ? Colors.orange : Colors.green,
                          child: Text((d['siswa_nama'] as String? ?? '?')[0], style: const TextStyle(color: Colors.white, fontSize: 13))),
                        title: Text('${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${d['jenis'] ?? '-'} | Nilai: ${d['nilai'] ?? '-'} | ${d['kelas_nama'] ?? '-'} | ${d['semester_nama'] ?? '-'}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: isDraft ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text(statusValidasi, style: TextStyle(fontSize: 11, color: isDraft ? Colors.orange : Colors.green, fontWeight: FontWeight.w600))),
                          if (isDraft) ...[
                            const SizedBox(width: 4),
                            IconButton(icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                              onPressed: () => _validasi(d['id'] as int), tooltip: 'Validasi'),
                          ],
                        ]),
                      ));
                    },
                  )),
      ]),
    );
  }
}
