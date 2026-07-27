import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _rekap;
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _tanggal = '';
  String _statusFilter = '';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final idx = _tabCtrl.index;
      if (idx == 2 || idx == 3) {
        _rekap = await AdminService.getRekapAbsensi(tanggalMulai: _tanggal);
      } else {
        final res = idx == 0
            ? await AdminService.getAbsensiGuru(page: _page, tanggal: _tanggal, status: _statusFilter)
            : await AdminService.getAbsensiSiswa(page: _page, tanggal: _tanggal, status: _statusFilter, kelasId: _tanggal);
        _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
      }
    } catch (_) { _data = []; _rekap = null; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) { _page = 1; _load(); },
          tabs: const [Tab(text: 'Guru'), Tab(text: 'Siswa'), Tab(text: 'Rekap'), Tab(text: 'Laporan')],
        ),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              decoration: InputDecoration(
                hintText: _tabCtrl.index >= 2 ? 'Tanggal (YYYY-MM-DD)' : 'Filter tanggal...',
                isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) { _tanggal = v; },
            )),
            if (_tabCtrl.index < 2) ...[  // hanya untuk tab Guru & Siswa
              const SizedBox(width: 8),
              SizedBox(width: 120, child: DropdownButtonFormField<String>(
                value: _statusFilter.isEmpty ? null : _statusFilter,
                isDense: true, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                hint: const Text('Status', style: TextStyle(fontSize: 13)),
                items: ['hadir', 'izin', 'sakit', 'alpa'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) { _statusFilter = v ?? ''; },
              )),
            ],
            const SizedBox(width: 8),
            IconButton(onPressed: () { _page = 1; _load(); }, icon: const Icon(Icons.search)),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tabCtrl.index == 2 || _tabCtrl.index == 3 ? _buildRekap() : _buildList()),
      ]),
    );
  }

  Widget _buildList() {
    if (_data.isEmpty) return Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey[500])));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _data.length + 1,
      itemBuilder: (_, i) {
        if (i == _data.length) {
          if (_page >= _totalPages) return const SizedBox.shrink();
          return TextButton(onPressed: () { _page++; _load(); }, child: const Text('Muat lebih banyak'));
        }
        final d = _data[i];
        final isGuru = _tabCtrl.index == 0;
        return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: _statusColor(d['status'] as String? ?? ''),
            child: Text((d[isGuru ? 'guru_nama' : 'siswa_nama'] as String? ?? '?')[0], style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          title: Text(d[isGuru ? 'guru_nama' : 'siswa_nama'] as String? ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${d['tanggal'] ?? '-'} | ${d['status'] ?? '-'}${d['kelas_nama'] != null ? ' | ${d['kelas_nama']}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(d['status'] as String? ?? '').withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(d['status'] as String? ?? '-', style: TextStyle(fontSize: 11, color: _statusColor(d['status'] as String? ?? ''), fontWeight: FontWeight.w600)),
          ),
        ));
      },
    );
  }

  Widget _buildRekap() {
    if (_rekap == null) return Center(child: Text('Masukkan filter tanggal untuk melihat rekap.', style: TextStyle(color: Colors.grey[500])));
    final siswa = _rekap!['siswa'] as Map<String, dynamic>? ?? {};
    final guru = _rekap!['guru'] as Map<String, dynamic>? ?? {};
    return ListView(padding: const EdgeInsets.all(12), children: [
      _rekapCard('Absensi Siswa', siswa, _rekap!['total_siswa'] as int? ?? 0, Icons.people_outline),
      const SizedBox(height: 12),
      _rekapCard('Absensi Guru', guru, _rekap!['total_guru'] as int? ?? 0, Icons.person_outline),
    ]);
  }

  Widget _rekapCard(String title, Map<String, dynamic> data, int total, IconData icon) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 20, color: Colors.green[700]), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 12),
      if (data.isEmpty)
        Text('Belum ada data.', style: TextStyle(fontSize: 13, color: Colors.grey[500]))
      else
        ...(data.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Text(e.key, style: const TextStyle(fontSize: 13),),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(e.key).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('${e.value}', style: TextStyle(fontSize: 12, color: _statusColor(e.key), fontWeight: FontWeight.w600))),
        ])))),
      const Divider(height: 20),
      Row(children: [const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const Spacer(), Text('$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700]))]),
    ])));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }
}
