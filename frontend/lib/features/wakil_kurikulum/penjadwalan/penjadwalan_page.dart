import 'dart:convert';
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

  // Kesiapan
  List<Map<String, dynamic>> _kesiapan = [];
  bool _kesiapanLoading = false;

  // Wali Kelas
  List<Map<String, dynamic>> _waliKelas = [];
  bool _waliKelasLoading = false;

  static const _hariList = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        if (_tabCtrl.index == 1) _loadKesiapan();
        if (_tabCtrl.index == 2) _loadWaliKelas();
      }
    });
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

  Future<void> _loadKesiapan() async {
    if (_filterSemester == null) return;
    setState(() => _kesiapanLoading = true);
    try {
      _kesiapan = (await WakilKurikulumService.getKesiapan(int.parse(_filterSemester!)))
          .cast<Map<String, dynamic>>();
    } catch (_) { _kesiapan = []; }
    if (mounted) setState(() => _kesiapanLoading = false);
  }

  Future<void> _loadWaliKelas() async {
    setState(() => _waliKelasLoading = true);
    try {
      _waliKelas = (await WakilKurikulumService.getWaliKelas())
          .cast<Map<String, dynamic>>();
    } catch (_) { _waliKelas = []; }
    if (mounted) setState(() => _waliKelasLoading = false);
  }

  List<Map<String, dynamic>> _refList(String key) => (_ref?[key] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjadwalan'),
        automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Jadwal'), Tab(text: 'Kesiapan'), Tab(text: 'Wali Kelas'),
        ]),
      ),
      body: _refLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabCtrl, children: [
              _buildJadwalTab(),
              _buildKesiapanTab(),
              _buildWaliKelasTab(),
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
            _filterDropdown(kelas, _filterKelas, 'Pilih Kelas', (v) {
              setState(() => _filterKelas = v);
              _loadJadwal();
            }, 200),
            const SizedBox(width: 12),
            _filterDropdown(sem, _filterSemester, 'Semester', (v) {
              setState(() => _filterSemester = v);
              _loadJadwal();
            }, 180),
          ]),
          if (_filterKelas != null && _filterSemester != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _ActionBtn(Icons.auto_awesome, 'Generate', Colors.blue, () => _generateJadwal()),
              _ActionBtn(Icons.add, 'Tambah', Colors.green, () => _showFormJadwal()),
              _ActionBtn(Icons.check_circle_outline, 'Validasi Semua', Colors.teal, () => _publikasiJadwal()),
              _ActionBtn(Icons.save_outlined, 'Simpan', Colors.indigo, () => _simpanJadwal()),
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  // ── Simpan Jadwal ──
  Future<void> _simpanJadwal() async {
    if (_jadwal.isEmpty) return;
    try {
      final data = _jadwal.map((j) => {
        'id': j['id'] as int,
        'kelas_id': j['kelas_id'] as int,
        'mata_pelajaran_id': j['mata_pelajaran_id'] as int,
        'guru_id': j['guru_id'] as int,
        'hari': j['hari'] as String,
        'jam_mulai': j['jam_mulai'] as String,
        'jam_selesai': j['jam_selesai'] as String,
        'semester_id': j['semester_id'] as int,
        if (j['ruangan_id'] != null) 'ruangan_id': j['ruangan_id'] as int,
      }).toList();

      final res = await WakilKurikulumService.simpanJadwal(data);
      if (mounted) {
        final msg = res['errors'] != null
            ? '${res['saved']} tersimpan, ${(res['errors'] as List).length} error'
            : '${res['saved']} jadwal tersimpan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        if (res['errors'] != null) {
          for (final e in res['errors'] as List) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
            );
          }
        }
      }
      _loadJadwal();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── ACTION BUTTONS ──
  Future<void> _generateJadwal() async {
    if (_filterSemester == null) return;
    final ok = await showConfirmDialog(context, title: 'Generate Jadwal',
        message: 'Generate otomatis akan menghapus jadwal draft dan membuat ulang berdasarkan Kesiapan Mengajar Guru dan data dari Admin Master Data. Lanjutkan?',
        confirmLabel: 'Generate');
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
        message: 'Validasi SEMUA jadwal draft semester ini? Setelah dipublikasi, jadwal tampil di Guru Mapel.',
        confirmLabel: 'Publikasi');
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
    String selectedHari = edit?['hari'] ?? 'Sabtu';

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
                onChanged: (v) { selectedHari = v ?? 'Sabtu'; setD(() {}); },
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
                else {
                  final cek = await WakilKurikulumService.cekBentrok(body);
                  if (cek['bentrok'] == true) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${cek['message']}'), backgroundColor: Colors.red));
                    return;
                  }
                  await WakilKurikulumService.createJadwal(body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadJadwal();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e'))); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════ KESIAPAN MENGAJAR TAB ══════════════════════════════
  Widget _buildKesiapanTab() {
    final sem = _refList('semester');

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _filterDropdown(sem, _filterSemester, 'Semester', (v) {
            setState(() => _filterSemester = v);
            _loadKesiapan();
          }, 200),
          const Spacer(),
          FilledButton.icon(
            onPressed: _filterSemester != null ? _simpanKesiapan : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Simpan Semua'),
          ),
        ]),
      ),
      Expanded(child: _kesiapanLoading
          ? const Center(child: CircularProgressIndicator())
          : _filterSemester == null
              ? Center(child: Text('Pilih semester terlebih dahulu', style: TextStyle(color: Colors.grey[500])))
              : _kesiapan.isEmpty
                  ? Center(child: Text('Belum ada data kesiapan. Pilih semester dan isi konfigurasi di bawah.', style: TextStyle(color: Colors.grey[500])))
                  : _buildKesiapanTable()),
    ]);
  }

  Widget _buildKesiapanTable() {
    final guruList = _kesiapan.map((k) => _KesiapanRowData.fromJson(k)).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 80,
          columns: const [
            DataColumn(label: Text('Guru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('NIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Hari Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('JP/Hari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('JP/Minggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kelas Diampu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Mapel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kapasitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: guruList.map((g) {
            final jpTerisi = g.jpTerisi;
            final jpMaxMinggu = g.jpMaxMinggu;
            final persen = jpMaxMinggu > 0 ? jpTerisi / jpMaxMinggu : 0.0;
            final capColor = persen >= 1.0 ? Colors.red : (persen >= 0.8 ? Colors.orange : Colors.green);

            return DataRow(cells: [
              DataCell(Text(g.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(Text(g.nip, style: const TextStyle(fontSize: 11))),
              DataCell(_HariCheckboxRow(
                nilai: g.hariAktif,
                onChanged: (v) {
                  setState(() => g.hariAktif = v);
                },
              )),
              DataCell(SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: g.jpMaxPerHari.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) g.jpMaxPerHari = val;
                  },
                ),
              )),
              DataCell(SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: g.jpMaxMinggu.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) g.jpMaxMinggu = val;
                  },
                ),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(g.kelasDiampu.map((k) => k['kelas_nama'] ?? '').join(', '),
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(g.mapelDiampu.map((m) => m['mapel_nama'] ?? '').join(', '),
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2),
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$jpTerisi/$jpMaxMinggu JP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: capColor)),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      value: persen.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      color: capColor,
                    ),
                  ),
                  if (persen >= 1.0)
                    Text('Kelebihan ${jpTerisi - jpMaxMinggu} JP', style: const TextStyle(fontSize: 9, color: Colors.red)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _simpanKesiapan() async {
    if (_filterSemester == null) return;
    setState(() => _kesiapanLoading = true);
    try {
      final data = _kesiapan.map((k) {
        final row = _KesiapanRowData.fromJson(k);
        return {
          'guru_id': row.guruId,
          'hari_aktif': row.hariAktif,
          'jp_max_per_hari': row.jpMaxPerHari,
          'jp_max_per_minggu': row.jpMaxMinggu,
        };
      }).toList();

      await WakilKurikulumService.batchUpdateKesiapan({
        'semester_id': int.parse(_filterSemester!),
        'data': data,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kesiapan berhasil disimpan'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
      );
    }
    if (mounted) setState(() => _kesiapanLoading = false);
  }

  // ══════════════════════════════ WALI KELAS TAB ══════════════════════════════
  Widget _buildWaliKelasTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.people_outline, color: Colors.blueGrey[600], size: 20),
          const SizedBox(width: 8),
          Text('Daftar Wali Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
          const Spacer(),
          TextButton.icon(
            onPressed: _loadWaliKelas,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ]),
      ),
      Expanded(child: _waliKelasLoading
          ? const Center(child: CircularProgressIndicator())
          : _waliKelas.isEmpty
              ? Center(child: Text('Belum ada data wali kelas.', style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _waliKelas.length,
                  itemBuilder: (_, i) {
                    final w = _waliKelas[i];
                    final adaKelas = w['kelas_id'] != null;
                    final jumlahSiswa = w['jumlah_siswa'] as int? ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: adaKelas ? Colors.blue[50] : Colors.grey[100],
                          radius: 22,
                          child: Icon(Icons.person, color: adaKelas ? Colors.blue[700] : Colors.grey[400], size: 22),
                        ),
                        title: Text(w['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIP: ${w['nip'] ?? '-'}'),
                            if (adaKelas) ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                Icon(Icons.class_outlined, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('${w['kelas_nama']}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                                Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('$jumlahSiswa Santri', style: TextStyle(color: Colors.grey[600])),
                              ]),
                            ],
                          ],
                        ),
                        trailing: adaKelas
                            ? Icon(Icons.check_circle, color: Colors.green[400], size: 20)
                            : Icon(Icons.remove_circle_outline, color: Colors.grey[400], size: 20),
                      ),
                    );
                  },
                )),
    ]);
  }

  // ── Shared helpers ──

  Widget _filterDropdown(List<Map<String, dynamic>> items, String? value, String hint, ValueChanged<String?> onChanged, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: const TextStyle(fontSize: 13)),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text('${e['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// ── Data class untuk Kesiapan ──

class _KesiapanRowData {
  final int guruId;
  final String nama;
  final String nip;
  List<String> hariAktif;
  int jpMaxPerHari;
  int jpMaxMinggu;
  final List<Map<String, dynamic>> kelasDiampu;
  final List<Map<String, dynamic>> mapelDiampu;
  final int jpTerisi;

  _KesiapanRowData({
    required this.guruId,
    required this.nama,
    required this.nip,
    required this.hariAktif,
    required this.jpMaxPerHari,
    required this.jpMaxMinggu,
    required this.kelasDiampu,
    required this.mapelDiampu,
    required this.jpTerisi,
  });

  factory _KesiapanRowData.fromJson(Map<String, dynamic> json) {
    List<String> hariAktif = [];
    if (json['hari_aktif'] is String) {
      try {
        final parsed = json['hari_aktif'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          hariAktif = (jsonDecode(parsed) as List).cast<String>();
        }
      } catch (_) {}
    } else if (json['hari_aktif'] is List) {
      hariAktif = (json['hari_aktif'] as List).cast<String>();
    }

    List<Map<String, dynamic>> kelasDiampu = [];
    if (json['kelas_diampu'] is String) {
      try {
        final parsed = json['kelas_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          kelasDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    } else if (json['kelas_diampu'] is List) {
      kelasDiampu = (json['kelas_diampu'] as List).cast<Map<String, dynamic>>();
    }

    List<Map<String, dynamic>> mapelDiampu = [];
    if (json['mapel_diampu'] is String) {
      try {
        final parsed = json['mapel_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          mapelDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    } else if (json['mapel_diampu'] is List) {
      mapelDiampu = (json['mapel_diampu'] as List).cast<Map<String, dynamic>>();
    }

    return _KesiapanRowData(
      guruId: json['id'] as int,
      nama: json['nama']?.toString() ?? '-',
      nip: json['nip']?.toString() ?? '-',
      hariAktif: hariAktif,
      jpMaxPerHari: json['jp_max_per_hari'] as int? ?? 8,
      jpMaxMinggu: json['jp_max_per_minggu'] as int? ?? 24,
      kelasDiampu: kelasDiampu,
      mapelDiampu: mapelDiampu,
      jpTerisi: json['jp_terisi'] as int? ?? 0,
    );
  }
}

// ── Hari Checkbox Row ──

class _HariCheckboxRow extends StatelessWidget {
  final List<String> nilai;
  final ValueChanged<List<String>> onChanged;
  static const _semuaHari = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];

  const _HariCheckboxRow({required this.nilai, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Wrap(
        spacing: 2,
        runSpacing: 0,
        children: _semuaHari.map((hari) {
          final checked = nilai.contains(hari);
          return FilterChip(
            label: Text(hari.substring(0, 2), style: const TextStyle(fontSize: 9)),
            selected: checked,
            onSelected: (v) {
              if (v) {
                onChanged([...nilai, hari]);
              } else {
                onChanged(nilai.where((h) => h != hari).toList());
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            labelStyle: TextStyle(fontSize: 9, color: checked ? Colors.white : Colors.grey[700]),
            selectedColor: Colors.green[700],
            checkmarkColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }
}

// ── Action Button ──

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
