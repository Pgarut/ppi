import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../services/guru_service.dart';

class AbsensiPageGuru extends StatefulWidget {
  const AbsensiPageGuru({super.key});

  @override
  State<AbsensiPageGuru> createState() => _AbsensiPageGuruState();
}

class _AbsensiPageGuruState extends State<AbsensiPageGuru> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text('Absensi', style: Theme.of(context).textTheme.headlineSmall),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.green[800],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[800],
          tabs: const [
            Tab(text: 'Input Absensi'),
            Tab(text: 'Riwayat'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _AbsensiInputForm(),
              _RiwayatAbsensi(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AbsensiInputForm extends StatefulWidget {
  const _AbsensiInputForm();

  @override
  State<_AbsensiInputForm> createState() => _AbsensiInputFormState();
}

class _AbsensiInputFormState extends State<_AbsensiInputForm> {
  final _tanggalCtl = TextEditingController();
  int? _kelasId, _mapelId;
  List<dynamic> _siswa = [];
  Map<dynamic, String> _statusMap = {};
  Map<dynamic, TextEditingController> _ketCtl = {};
  Map<dynamic, dynamic> _existing = {};
  List<dynamic> _kelas = [], _mapel = [];
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadReferensi();
  }

  Future<void> _loadReferensi() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _kelas = data['kelas'] as List<dynamic>? ?? [];
      _mapel = data['mata_pelajaran'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadSiswa() async {
    if (_kelasId == null) return;
    setState(() => _loading = true);
    try {
      final data = await GuruService.getSiswaPerKelasAbsensi(
        _kelasId.toString(),
        tanggal: _tanggalCtl.text.isNotEmpty ? _tanggalCtl.text : null,
        mataPelajaranId: _mapelId?.toString(),
      );
      _siswa = data['siswa'] as List<dynamic>? ?? [];
      _existing = data['existing'] as Map<dynamic, dynamic>? ?? {};
      _statusMap = {};
      _ketCtl = {};
      for (final s in _siswa) {
        final id = s['id'];
        final ex = _existing[id];
        _statusMap[id] = (ex != null ? ex['status'] as String : 'hadir');
        _ketCtl[id] = TextEditingController(text: ex != null ? ex['keterangan'] as String? ?? '' : '');
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _simpan() async {
    if (_kelasId == null || _tanggalCtl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final entries = _siswa.map((s) {
        final id = s['id'];
        return {
          'siswa_id': id,
          'status': _statusMap[id] ?? 'hadir',
          'keterangan': _ketCtl[id]?.text.isNotEmpty == true ? _ketCtl[id]!.text : null,
        };
      }).toList();

      await GuruService.inputAbsensiMassal({
        'kelas_id': _kelasId,
        'mata_pelajaran_id': _mapelId,
        'tanggal': _tanggalCtl.text,
        'entries': entries,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Absensi tersimpan'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    for (final c in _ketCtl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(width: 200, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
              items: _kelas.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _kelasId = v),
            )),
            SizedBox(width: 200, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
              items: _mapel.map((m) => DropdownMenuItem(value: m['id'] as int, child: Text(m['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _mapelId = v),
            )),
            SizedBox(width: 200, child: TextField(
              controller: _tanggalCtl,
              decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) _tanggalCtl.text = d.toIso8601String().substring(0, 10);
              },
            )),
            ElevatedButton(onPressed: _loadSiswa, child: const Text('Muat Siswa')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && _siswa.isNotEmpty) ...[
          Row(
            children: [
              const Text('Status Cepat: '),
              _statusBtn('Hadir', 'hadir', Colors.green),
              _statusBtn('Izin', 'izin', Colors.orange),
              _statusBtn('Sakit', 'sakit', Colors.blue),
              _statusBtn('Alpa', 'alpa', Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          DataTable(
            columns: const [
              DataColumn(label: Text('NIS')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: _siswa.map((s) {
              final id = s['id'];
              return DataRow(cells: [
                DataCell(Text(s['nis']?.toString() ?? '')),
                DataCell(Text(s['nama']?.toString() ?? '')),
                DataCell(DropdownButton<String>(
                  value: _statusMap[id] ?? 'hadir',
                  items: ['hadir', 'izin', 'sakit', 'alpa'].map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                  onChanged: (v) => setState(() => _statusMap[id] = v!),
                )),
                DataCell(SizedBox(width: 150, child: TextField(
                  controller: _ketCtl[id],
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Keterangan'),
                ))),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _simpan,
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: const Text('Simpan Absensi'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ],
    );
  }

  Widget _statusBtn(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        icon: Icon(Icons.check_circle, color: color, size: 18),
        label: Text(label),
        onPressed: () {
          for (final s in _siswa) _statusMap[s['id']] = val;
          setState(() {});
        },
      ),
    );
  }
}

class _RiwayatAbsensi extends StatefulWidget {
  const _RiwayatAbsensi();

  @override
  State<_RiwayatAbsensi> createState() => _RiwayatAbsensiState();
}

class _RiwayatAbsensiState extends State<_RiwayatAbsensi> {
  List<dynamic> _items = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await GuruService.getAbsensi(page: _page);
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada riwayat absensi')))
        else ...[
          DataTable(
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Siswa')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Mapel')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: _items.map((item) {
              final r = item as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(r['tanggal']?.toString() ?? '')),
                DataCell(Text(r['siswa_nama']?.toString() ?? '')),
                DataCell(Text(r['kelas_nama']?.toString() ?? '')),
                DataCell(Text(r['mapel_nama']?.toString() ?? '-')),
                DataCell(_statusChip(r['status']?.toString() ?? '')),
                DataCell(Text(r['keterangan']?.toString() ?? '-')),
              ]);
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 ? () { _page--; _load(); } : null,
              ),
              Text('Halaman $_page dari $_totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < _totalPages ? () { _page++; _load(); } : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'hadir': color = Colors.green; break;
      case 'izin': color = Colors.orange; break;
      case 'sakit': color = Colors.blue; break;
      case 'alpa': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
