import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../services/guru_service.dart';

class NilaiPageGuru extends StatefulWidget {
  const NilaiPageGuru({super.key});

  @override
  State<NilaiPageGuru> createState() => _NilaiPageGuruState();
}

class _NilaiPageGuruState extends State<NilaiPageGuru> {
  int? _kelasId, _mapelId, _semesterId;
  String _jenis = 'harian';
  List<dynamic> _siswa = [], _kelas = [], _mapel = [], _semester = [];
  Map<dynamic, TextEditingController> _nilaiCtl = {};
  Map<dynamic, TextEditingController> _ketCtl = {};
  bool _loading = true, _saving = false;

  final _jenisList = ['harian', 'tugas', 'uts', 'uas', 'akhir'];

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
      _semester = data['semester'] as List<dynamic>? ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadSiswa() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null) return;
    setState(() => _loading = true);
    try {
      final data = await GuruService.getSiswaPerKelasNilai(
        _kelasId.toString(), _mapelId.toString(), _semesterId.toString(), jenis: _jenis,
      );
      _siswa = data['siswa'] as List<dynamic>? ?? [];
      final existing = data['existing'] as Map<dynamic, dynamic>? ?? {};
      _nilaiCtl = {};
      _ketCtl = {};
      for (final s in _siswa) {
        final id = s['id'];
        final ex = existing[id];
        _nilaiCtl[id] = TextEditingController(text: ex != null ? '${ex['nilai']}' : '');
        _ketCtl[id] = TextEditingController(text: ex != null ? ex['keterangan'] as String? ?? '' : '');
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _simpan() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null) return;
    setState(() => _saving = true);
    try {
      final entries = _siswa.map((s) {
        final id = s['id'];
        return {
          'siswa_id': id,
          'nilai': double.tryParse(_nilaiCtl[id]?.text ?? '') ?? 0,
          'keterangan': _ketCtl[id]?.text.isNotEmpty == true ? _ketCtl[id]!.text : null,
        };
      }).toList();

      await GuruService.inputNilaiMassal({
        'kelas_id': _kelasId,
        'mata_pelajaran_id': _mapelId,
        'semester_id': _semesterId,
        'jenis': _jenis,
        'entries': entries,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nilai tersimpan'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    for (final c in _nilaiCtl.values) c.dispose();
    for (final c in _ketCtl.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Input Nilai', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 12,
          children: [
            SizedBox(width: 180, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
              items: _kelas.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _kelasId = v),
            )),
            SizedBox(width: 180, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Mapel', border: OutlineInputBorder()),
              items: _mapel.map((m) => DropdownMenuItem(value: m['id'] as int, child: Text(m['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _mapelId = v),
            )),
            SizedBox(width: 150, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama'] as String? ?? ''))).toList(),
              onChanged: (v) => setState(() => _semesterId = v),
            )),
            SizedBox(width: 130, child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
              value: _jenis,
              items: _jenisList.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
              onChanged: (v) => setState(() => _jenis = v!),
            )),
            ElevatedButton(onPressed: _loadSiswa, child: const Text('Muat Siswa')),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading && _siswa.isNotEmpty) ...[
          DataTable(
            columns: const [
              DataColumn(label: Text('NIS')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Nilai')),
              DataColumn(label: Text('Keterangan')),
            ],
            rows: _siswa.map((s) {
              final id = s['id'];
              return DataRow(cells: [
                DataCell(Text(s['nis']?.toString() ?? '')),
                DataCell(Text(s['nama']?.toString() ?? '')),
                DataCell(SizedBox(width: 100, child: TextField(
                  controller: _nilaiCtl[id],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ))),
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
            label: const Text('Simpan Nilai'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ],
    );
  }
}


