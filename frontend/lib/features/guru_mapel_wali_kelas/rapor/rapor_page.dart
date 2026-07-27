import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../services/guru_service.dart';

class RaporPageGuru extends StatefulWidget {
  const RaporPageGuru({super.key});

  @override
  State<RaporPageGuru> createState() => _RaporPageGuruState();
}

class _RaporPageGuruState extends State<RaporPageGuru> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          child: Text('Rapor', style: Theme.of(context).textTheme.headlineSmall),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.green[800],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[800],
          tabs: const [
            Tab(text: 'Input Rapor'),
            Tab(text: 'Lihat Rapor'),
            Tab(text: 'Status Pengiriman'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _InputRapor(),
              _LihatRapor(),
              _StatusPengiriman(),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputRapor extends StatefulWidget {
  const _InputRapor();

  @override
  State<_InputRapor> createState() => _InputRaporState();
}

class _InputRaporState extends State<_InputRapor> {
  int? _siswaId, _semesterId, _kelasId, _mapelId;
  List<dynamic> _siswa = [], _semester = [], _kelas = [], _mapel = [];
  final _nilaiCtl = TextEditingController();
  final _predikatCtl = TextEditingController();
  final _catatanCtl = TextEditingController();
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
      _semester = data['semester'] as List<dynamic>? ?? [];
      _kelas = data['kelas'] as List<dynamic>? ?? [];
      _mapel = data['mata_pelajaran'] as List<dynamic>? ?? [];
      _siswa = data['siswa'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _simpan() async {
    if (_siswaId == null || _semesterId == null || _kelasId == null || _mapelId == null) return;
    setState(() => _saving = true);
    try {
      await GuruService.saveRapor({
        'siswa_id': _siswaId,
        'kelas_id': _kelasId,
        'semester_id': _semesterId,
        'mata_pelajaran_id': _mapelId,
        'nilai_akhir': double.tryParse(_nilaiCtl.text) ?? 0,
        'predikat': _predikatCtl.text,
        'catatan_wali_kelas': _catatanCtl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor tersimpan'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nilaiCtl.dispose();
    _predikatCtl.dispose();
    _catatanCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(width: 200, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Siswa', border: OutlineInputBorder()),
              items: _siswa.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text('${s['nis']} - ${s['nama']}'))).toList(),
              onChanged: (v) => setState(() => _siswaId = v),
            )),
            SizedBox(width: 150, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
              items: _kelas.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _kelasId = v),
            )),
            SizedBox(width: 150, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _semesterId = v),
            )),
            SizedBox(width: 180, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
              items: _mapel.map((m) => DropdownMenuItem(value: m['id'] as int, child: Text(m['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _mapelId = v),
            )),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(width: 300, child: TextField(
          controller: _nilaiCtl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nilai Akhir', border: OutlineInputBorder()),
        )),
        const SizedBox(height: 12),
        SizedBox(width: 300, child: TextField(
          controller: _predikatCtl,
          decoration: const InputDecoration(labelText: 'Predikat (A/B/C/D)', border: OutlineInputBorder()),
        )),
        const SizedBox(height: 12),
        SizedBox(width: 500, child: TextField(
          controller: _catatanCtl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Catatan Wali Kelas', border: OutlineInputBorder()),
        )),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saving ? null : _simpan,
          icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
          label: const Text('Simpan Rapor'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

class _LihatRapor extends StatefulWidget {
  const _LihatRapor();

  @override
  State<_LihatRapor> createState() => _LihatRaporState();
}

class _LihatRaporState extends State<_LihatRapor> {
  List<dynamic> _rapor = [];
  List<dynamic> _siswa = [], _semester = [];
  int? _siswaId, _semesterId;
  bool _loading = true, _loadingRapor = false;

  @override
  void initState() {
    super.initState();
    _loadReferensi();
  }

  Future<void> _loadReferensi() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _semester = data['semester'] as List<dynamic>? ?? [];
      _siswa = data['siswa'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadRapor() async {
    setState(() => _loadingRapor = true);
    try {
      _rapor = await GuruService.getRapor(
        siswaId: _siswaId?.toString(),
        semesterId: _semesterId?.toString(),
      );
    } catch (_) {
      _rapor = [];
    }
    setState(() => _loadingRapor = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(width: 200, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Siswa', border: OutlineInputBorder()),
              items: _siswa.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text('${s['nis']} - ${s['nama']}'))).toList(),
              onChanged: (v) => setState(() => _siswaId = v),
            )),
            SizedBox(width: 150, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              value: _semesterId,
              items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _semesterId = v),
            )),
            ElevatedButton(onPressed: _loadRapor, child: const Text('Cari')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingRapor)
          const Center(child: CircularProgressIndicator())
        else if (_rapor.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada data rapor')))
        else ...[
          DataTable(
            columns: const [
              DataColumn(label: Text('Siswa')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Mapel')),
              DataColumn(label: Text('Nilai Akhir')),
              DataColumn(label: Text('Predikat')),
              DataColumn(label: Text('Catatan')),
            ],
            rows: _rapor.map((item) {
              final r = item as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Text(r['siswa_nama']?.toString() ?? '')),
                DataCell(Text(r['kelas_nama']?.toString() ?? '')),
                DataCell(Text(r['mapel_nama']?.toString() ?? '')),
                DataCell(Text(r['nilai_akhir']?.toString() ?? '-')),
                DataCell(Text(r['predikat']?.toString() ?? '-')),
                DataCell(SizedBox(width: 150, child: Text(r['catatan_wali_kelas']?.toString() ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis))),
              ]);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _StatusPengiriman extends StatefulWidget {
  const _StatusPengiriman();

  @override
  State<_StatusPengiriman> createState() => _StatusPengirimanState();
}

class _StatusPengirimanState extends State<_StatusPengiriman> {
  List<dynamic> _rapor = [];
  List<dynamic> _semester = [];
  int? _semesterId;
  bool _loading = true, _loadingData = false;

  @override
  void initState() {
    super.initState();
    _loadReferensi();
  }

  Future<void> _loadReferensi() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _semester = data['semester'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      _rapor = await GuruService.getRapor(semesterId: _semesterId?.toString());
    } catch (_) {
      _rapor = [];
    }
    setState(() => _loadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(width: 200, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              value: _semesterId,
              items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _semesterId = v),
            )),
            ElevatedButton(onPressed: _loadData, child: const Text('Tampilkan')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingData)
          const Center(child: CircularProgressIndicator())
        else if (_rapor.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada data rapor untuk semester ini')))
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Pengiriman Rapor', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _statRow('Total Entri Rapor', '${_rapor.length}'),
                  _statRow('Dengan Nilai Akhir', '${_rapor.where((r) => r['nilai_akhir'] != null).length}'),
                  _statRow('Dengan Predikat', '${_rapor.where((r) => r['predikat'] != null && r['predikat'].toString().isNotEmpty).length}'),
                  _statRow('Dengan Catatan', '${_rapor.where((r) => r['catatan_wali_kelas'] != null && r['catatan_wali_kelas'].toString().isNotEmpty).length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Siswa')),
              DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Mapel')),
              DataColumn(label: Text('Nilai')),
              DataColumn(label: Text('Predikat')),
              DataColumn(label: Text('Status')),
            ],
            rows: _rapor.map((item) {
              final r = item as Map<String, dynamic>;
              final hasNilai = r['nilai_akhir'] != null;
              final hasPredikat = r['predikat'] != null && r['predikat'].toString().isNotEmpty;
              final status = hasNilai && hasPredikat ? 'Lengkap' : 'Belum Lengkap';
              return DataRow(cells: [
                DataCell(Text(r['siswa_nama']?.toString() ?? '')),
                DataCell(Text(r['kelas_nama']?.toString() ?? '')),
                DataCell(Text(r['mapel_nama']?.toString() ?? '')),
                DataCell(Text(r['nilai_akhir']?.toString() ?? '-')),
                DataCell(Text(r['predikat']?.toString() ?? '-')),
                DataCell(_statusChip(status)),
              ]);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'Lengkap' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
