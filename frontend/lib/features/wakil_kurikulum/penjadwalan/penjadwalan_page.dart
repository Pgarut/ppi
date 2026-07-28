import 'package:flutter/material.dart';
import '../services/wakil_kurikulum_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class PenjadwalanPage extends StatefulWidget {
  const PenjadwalanPage({super.key});

  @override
  State<PenjadwalanPage> createState() => _PenjadwalanPageState();
}

class _PenjadwalanPageState extends State<PenjadwalanPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic>? _ref;
  bool _refLoading = true;
  List<Map<String, dynamic>> _jadwal = [];
  List<Map<String, dynamic>> _jpSlots = [];
  String? _filterKelas, _filterSemester;
  bool _jadwalLoading = false;

  // Distribusi
  List<Map<String, dynamic>> _distribusi = [];
  List<Map<String, dynamic>> _beban = [];

  static const _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadRef();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadRef() async {
    try {
      _ref = await WakilKurikulumService.getReferensi();
      _jpSlots = (await WakilKurikulumService.getJpSlots()).cast<Map<String, dynamic>>();
    } catch (_) {}
    setState(() => _refLoading = false);
    _loadJadwal();
    _loadDistribusi();
    _loadBeban();
  }

  Future<void> _loadJadwal() async {
    if (_filterKelas == null || _filterSemester == null) return;
    setState(() => _jadwalLoading = true);
    try {
      final res = await WakilKurikulumService.getJadwalPerKelas(_filterKelas!, _filterSemester!);
      _jadwal = res.cast<Map<String, dynamic>>();
    } catch (_) { _jadwal = []; }
    if (mounted) setState(() => _jadwalLoading = false);
  }

  Future<void> _loadDistribusi() async {
    try { _distribusi = (await WakilKurikulumService.getDistribusiMengajar()).cast<Map<String, dynamic>>(); }
    catch (_) {}
  }

  Future<void> _loadBeban() async {
    try { _beban = (await WakilKurikulumService.getBebanMengajar()).cast<Map<String, dynamic>>(); }
    catch (_) {}
  }

  List<Map<String, dynamic>> _refList(String key) => (_ref?[key] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // ── BUILD ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjadwalan'),
        automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Jadwal'), Tab(text: 'Distribusi'), Tab(text: 'Beban'),
        ]),
      ),
      body: _refLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildJadwalTab(),
              _buildDistribusiTab(),
              _buildBebanTab(),
            ]),
    );
  }

  // ══════════════════════════════ JADWAL TAB ══════════════════════════════
  Widget _buildJadwalTab() {
    final kelas = _refList('kelas');
    final sem = _refList('semester');

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            DropdownButtonHideUnderline(
              child: Container(
                width: 200, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _filterKelas, hint: const Text('Pilih Kelas', style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  items: kelas.map((k) => DropdownMenuItem(value: '${k['id']}', child: Text('${k['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { setState(() => _filterKelas = v); _loadJadwal(); },
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: Container(
                width: 180, padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: _filterSemester, hint: const Text('Semester', style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  items: sem.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { setState(() => _filterSemester = v); _loadJadwal(); },
                ),
              ),
            ),
          ]),
          if (_filterKelas != null && _filterSemester != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              _ActionBtn(Icons.auto_awesome, 'Generate', Colors.blue, () => _generateJadwal()),
              const SizedBox(width: 8),
              _ActionBtn(Icons.add, 'Tambah', Colors.green, () => _showFormJadwal()),
              const SizedBox(width: 8),
              _ActionBtn(Icons.check_circle_outline, 'Validasi Semua', Colors.teal, () => _publikasiJadwal()),
              const Spacer(),
              _ActionBtn(Icons.undo, 'Reset', Colors.red, () => _resetJadwal()),
            ]),
          ],
        ]),
      ),
      Expanded(child: _buildTimetable()),
    ]);
  }

  Widget _buildTimetable() {
    if (_filterKelas == null || _filterSemester == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.touch_app, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Pilih kelas dan semester untuk melihat jadwal', style: TextStyle(color: Colors.grey[500])),
      ]));
    }

    if (_jadwalLoading) return const Center(child: CircularProgressIndicator());

    if (_jadwal.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Belum ada jadwal. Klik Generate atau Tambah Manual.', style: TextStyle(color: Colors.grey[500])),
      ]));
    }

    final map = <String, Map<String, Map<String, dynamic>>>{};
    for (final j in _jadwal) {
      final hari = j['hari'] as String;
      final jpKey = _findJpKey(j['jam_mulai'] as String, j['jam_selesai'] as String);
      map.putIfAbsent(jpKey, () => {});
      map[jpKey]![hari] = j;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 8,
          headingRowHeight: 40,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 56,
          columns: [
            const DataColumn(label: Text('JP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ..._hariList.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          ],
          rows: _jpSlots.map((jp) {
            final jpKode = jp['kode'] as String;
            final jpWaktu = '${jp['mulai']}-${jp['selesai']}';

            return DataRow(cells: [
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('$jpKode\n$jpWaktu', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
              )),
              ..._hariList.map((hari) {
                final entry = map[jpKode]?[hari];
                return DataCell(
                  entry != null
                      ? _buildScheduleCell(entry)
                      : DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) => _moveToSlot(details.data, jpKode, hari),
                          builder: (ctx, candidates, rejected) => Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!, width: 0.5),
                              color: candidates.isNotEmpty ? Colors.blue[50] : null,
                            ),
                          ),
                        ),
                  placeholder: true,
                );
              }),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleCell(Map<String, dynamic> j) {
    final tervalidasi = j['status_validasi'] == 'tervalidasi';
    final mapelNama = j['mapel_nama']?.toString() ?? '-';
    final guruNama = j['guru_nama']?.toString() ?? '-';
    final color = tervalidasi ? Colors.green : Colors.orange;

    return LongPressDraggable<Map<String, dynamic>>(
      data: j,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
          child: Text(mapelNama, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Container(height: 48, decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.grey[100],
      )),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(mapelNama, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color[800]), overflow: TextOverflow.ellipsis),
          Text(guruNama, style: TextStyle(fontSize: 8, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  String _findJpKey(String mulai, String selesai) {
    for (final jp in _jpSlots) {
      if (jp['mulai'] == mulai && jp['selesai'] == selesai) return jp['kode'] as String;
    }
    // Fallback: cari berdasarkan jam mulai
    for (final jp in _jpSlots) {
      if (jp['mulai'] == mulai) return jp['kode'] as String;
    }
    return '$mulai-$selesai';
  }

  Future<void> _moveToSlot(Map<String, dynamic> jadwal, String jpKode, String hari) async {
    final jp = _jpSlots.firstWhere((j) => j['kode'] == jpKode, orElse: () => <String, dynamic>{});
    if (jp.isEmpty) return;

    final id = jadwal['id'] as int;
    try {
      await WakilKurikulumService.updateJadwal(id, {
        'hari': hari,
        'jam_mulai': jp['mulai'],
        'jam_selesai': jp['selesai'],
      });
      _loadJadwal();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${jadwal['mapel_nama']} dipindah ke $hari $jpKode'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── ACTION BUTTONS ──
  Future<void> _generateJadwal() async {
    if (_filterSemester == null) return;
    final ok = await showConfirmDialog(context, title: 'Generate Jadwal',
        message: 'Generate otomatis akan menghapus jadwal draft dan membuat ulang berdasarkan distribusi mengajar. Lanjutkan?');
    if (!ok) return;

    try {
      final res = await WakilKurikulumService.generateJadwal(int.parse(_filterSemester!));
      _loadJadwal();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${res['message'] ?? 'Selesai'}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetJadwal() async {
    if (_filterSemester == null) return;
    final ok = await showConfirmDialog(context, title: 'Reset Jadwal',
        message: 'Hapus SEMUA jadwal draft semester ini? Jadwal tervalidasi tetap aman.');
    if (!ok) return;

    try {
      await WakilKurikulumService.resetJadwal(int.parse(_filterSemester!));
      _loadJadwal();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal direset'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _publikasiJadwal() async {
    if (_filterSemester == null) return;
    final ok = await showConfirmDialog(context, title: 'Publikasi Jadwal',
        message: 'Validasi SEMUA jadwal draft semester ini? Setelah dipublikasi, jadwal tidak bisa diedit (kecuali direset).');
    if (!ok) return;

    try {
      await WakilKurikulumService.publikasiJadwal(int.parse(_filterSemester!));
      _loadJadwal();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal dipublikasikan'), backgroundColor: Colors.teal));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  // ── FORM JADWAL ──
  Future<void> _showFormJadwal({Map<String, dynamic>? edit}) async {
    final kelas = _refList('kelas');
    final mapel = _refList('mapel');
    final guru = _refList('guru');
    final ruangan = _refList('ruangan');
    final sem = _refList('semester');

    String? selectedKelas = edit?['kelas_id']?.toString() ?? _filterKelas;
    String? selectedMapel = edit?['mata_pelajaran_id']?.toString();
    String? selectedGuru = edit?['guru_id']?.toString();
    String? selectedRuang = edit?['ruangan_id']?.toString();
    String? selectedSemester = edit?['semester_id']?.toString() ?? _filterSemester;
    String selectedHari = edit?['hari'] ?? 'Senin';

    final jpKeys = _jpSlots.map((j) => '${j['kode']} (${j['mulai']}-${j['selesai']})').toList();
    String? selectedJp;
    if (edit != null) {
      final jpKey = _findJpKey(edit['jam_mulai'] as String, edit['jam_selesai'] as String);
      selectedJp = _jpSlots.indexWhere((j) => j['kode'] == jpKey) >= 0
          ? '$jpKey (${edit['jam_mulai']}-${edit['jam_selesai']})'
          : null;
    }

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(edit != null ? 'Edit Jadwal' : 'Tambah Jadwal'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: selectedKelas, decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
                items: kelas.map((k) => DropdownMenuItem(value: '${k['id']}', child: Text('${k['nama']}'))).toList(),
                onChanged: (v) { selectedKelas = v; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedMapel, decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
                items: mapel.map((m) => DropdownMenuItem(value: '${m['id']}', child: Text('${m['nama']}'))).toList(),
                onChanged: (v) { selectedMapel = v; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGuru, decoration: const InputDecoration(labelText: 'Asatidz', border: OutlineInputBorder()),
                items: guru.map((g) => DropdownMenuItem(value: '${g['id']}', child: Text('${g['nama']}'))).toList(),
                onChanged: (v) { selectedGuru = v; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRuang, decoration: const InputDecoration(labelText: 'Ruangan', border: OutlineInputBorder()),
                items: [const DropdownMenuItem(value: null, child: Text('- Tanpa Ruangan -')),
                  ...ruangan.map((r) => DropdownMenuItem(value: '${r['id']}', child: Text('${r['nama']}'))),
                ],
                onChanged: (v) { selectedRuang = v; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedHari, decoration: const InputDecoration(labelText: 'Hari', border: OutlineInputBorder()),
                items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (v) { selectedHari = v ?? 'Senin'; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedJp, decoration: const InputDecoration(labelText: 'Jam Pelajaran', border: OutlineInputBorder()),
                items: jpKeys.map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
                onChanged: (v) { selectedJp = v; setD(() {}); },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedSemester, decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                items: sem.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['nama']}'))).toList(),
                onChanged: (v) { selectedSemester = v; setD(() {}); },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              String? jamMulai, jamSelesai;
              if (selectedJp != null) {
                final match = RegExp(r'\((\d{2}:\d{2})-(\d{2}:\d{2})\)').firstMatch(selectedJp!);
                if (match != null) { jamMulai = match.group(1); jamSelesai = match.group(2); }
              }
              final body = {
                'kelas_id': int.tryParse(selectedKelas ?? ''),
                'mata_pelajaran_id': int.tryParse(selectedMapel ?? ''),
                'guru_id': int.tryParse(selectedGuru ?? ''),
                'ruangan_id': int.tryParse(selectedRuang ?? ''),
                'hari': selectedHari,
                'jam_mulai': jamMulai ?? (edit?['jam_mulai'] ?? '07:00'),
                'jam_selesai': jamSelesai ?? (edit?['jam_selesai'] ?? '07:45'),
                'semester_id': int.tryParse(selectedSemester ?? ''),
              };
              try {
                if (edit != null) { await WakilKurikulumService.updateJadwal(edit['id'] as int, body); }
                else { await WakilKurikulumService.createJadwal(body); }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadJadwal();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════ DISTRIBUSI TAB ══════════════════════════════
  Widget _buildDistribusiTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _showFormDistribusi, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Distribusi')),
        ]),
      ),
      Expanded(child: _distribusi.isEmpty
          ? Center(child: Text('Belum ada distribusi.', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _distribusi.length,
              itemBuilder: (_, i) {
                final d = _distribusi[i];
                return Card(child: ListTile(
                  title: Text('${d['guru_nama'] ?? '-'} — ${d['mapel_nama'] ?? '-'}'),
                  subtitle: Text('Kelas: ${d['kelas_nama'] ?? '-'} | Semester: ${d['semester_nama'] ?? '-'}'),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => _deleteDistribusi(d['id'] as int)),
                ));
              },
            )),
    ]);
  }

  Future<void> _showFormDistribusi() async {
    final guru = _refList('guru');
    final mapel = _refList('mapel');
    final kelas = _refList('kelas');
    final sem = _refList('semester');
    String? g, m, k, s;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah Distribusi'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Asatidz', border: OutlineInputBorder()),
              items: guru.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['nama']}'))).toList(),
              onChanged: (v) { g = v; setD(() {}); }),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Mapel', border: OutlineInputBorder()),
              items: mapel.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['nama']}'))).toList(),
              onChanged: (v) { m = v; setD(() {}); }),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
              items: kelas.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['nama']}'))).toList(),
              onChanged: (v) { k = v; setD(() {}); }),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
              items: sem.map((x) => DropdownMenuItem(value: '${x['id']}', child: Text('${x['nama']}'))).toList(),
              onChanged: (v) { s = v; setD(() {}); }),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await WakilKurikulumService.createDistribusi({
                  'guru_id': int.tryParse(g ?? ''), 'mata_pelajaran_id': int.tryParse(m ?? ''),
                  'kelas_id': int.tryParse(k ?? ''), 'semester_id': int.tryParse(s ?? ''),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadDistribusi(); _loadBeban();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDistribusi(int id) async {
    final ok = await showConfirmDialog(context, title: 'Hapus', message: 'Yakin hapus distribusi?');
    if (!ok) return;
    try { await WakilKurikulumService.deleteDistribusi(id); _loadDistribusi(); _loadBeban(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  // ══════════════════════════════ BEBAN TAB ══════════════════════════════
  Widget _buildBebanTab() {
    if (_beban.isEmpty) return Center(child: Text('Belum ada data.', style: TextStyle(color: Colors.grey[500])));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _beban.length,
      itemBuilder: (_, i) {
        final b = _beban[i];
        return Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.blue[50], radius: 20,
            child: Text('${b['total_mapel'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
          title: Text(b['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('NIP: ${b['nip'] ?? '-'}'),
          trailing: Text('${b['total_mapel'] ?? 0} Mapel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        ));
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn(this.icon, this.label, this.color, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withOpacity(0.3))),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
