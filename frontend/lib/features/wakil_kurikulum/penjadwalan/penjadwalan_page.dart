import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/wakil_kurikulum_service.dart';
import '../../../shared/widgets/app_utils.dart';

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
  bool _jadwalLoading = false;

  // Filters
  String? _filterTingkat;
  String? _filterGenre;
  String? _filterSemester;
  String? _selectedHari;

  // Kesiapan
  List<Map<String, dynamic>> _kesiapan = [];
  bool _kesiapanLoading = false;

  // Wali Kelas
  List<Map<String, dynamic>> _waliKelas = [];
  bool _waliKelasLoading = false;

  static const _hariList = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
  static const _genreList = ['Pagi', 'Siang', 'Full Day'];

  // Kegiatan tetap
  final List<Map<String, dynamic>> _kegiatanTetap = [
    {'nama': 'Istirahat RG', 'tipe': 'istirahat'},
    {'nama': 'Istirahat UG', 'tipe': 'istirahat'},
    {'nama': 'Tahfidz & Tahsin', 'tipe': 'kegiatan'},
    {'nama': 'Murojaah', 'tipe': 'kegiatan'},
    {'nama': "Ba'at", 'tipe': 'kegiatan'},
  ];

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
    _selectedHari = _hariList.first;
    _loadRef();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRef() async {
    try {
      _ref = await WakilKurikulumService.getReferensi();
      _jpSlots = (await WakilKurikulumService.getJpSlots()).cast<Map<String, dynamic>>();
    } catch (_) {}
    setState(() => _refLoading = false);
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    if (_filterSemester == null) return;
    setState(() => _jadwalLoading = true);
    try {
      final allKelas = _refList('kelas');
      List<Map<String, dynamic>> allJadwal = [];
      for (final k in allKelas) {
        final kelasId = k['id'].toString();
        try {
          final res = await WakilKurikulumService.getJadwalPerKelas(kelasId, _filterSemester!);
          final list = res.cast<Map<String, dynamic>>();
          allJadwal.addAll(list);
        } catch (_) {}
      }
      _jadwal = allJadwal;
    } catch (_) {
      _jadwal = [];
    }
    if (mounted) setState(() => _jadwalLoading = false);
  }

  Future<void> _loadKesiapan() async {
    if (_filterSemester == null) return;
    setState(() => _kesiapanLoading = true);
    try {
      _kesiapan = (await WakilKurikulumService.getKesiapan(int.parse(_filterSemester!)))
          .cast<Map<String, dynamic>>();
    } catch (_) {
      _kesiapan = [];
    }
    if (mounted) setState(() => _kesiapanLoading = false);
  }

  Future<void> _loadWaliKelas() async {
    setState(() => _waliKelasLoading = true);
    try {
      _waliKelas = (await WakilKurikulumService.getWaliKelas())
          .cast<Map<String, dynamic>>();
    } catch (_) {
      _waliKelas = [];
    }
    if (mounted) setState(() => _waliKelasLoading = false);
  }

  List<Map<String, dynamic>> _refList(String key) =>
      (_ref?[key] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // ══════════════════════════════ MAIN BUILD ══════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.grey500,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Jadwal'),
              Tab(text: 'Kesiapan'),
              Tab(text: 'Wali Kelas'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _refLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : TabBarView(controller: _tabCtrl, children: [
                  _buildJadwalTab(),
                  _buildKesiapanTab(),
                  _buildWaliKelasTab(),
                ]),
        ),
      ],
    );
  }

  // ══════════════════════════════ JADWAL TAB ══════════════════════════════

  Widget _buildJadwalTab() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _jadwalLoading
              ? const Center(child: CircularProgressIndicator())
              : _filterSemester == null
                  ? _buildEmptyState('Pilih semester terlebih dahulu')
                  : _buildTwoColumnLayout(),
        ),
      ],
    );
  }

  // ── Toolbar ──

  Widget _buildToolbar() {
    final tingkat = _refList('tingkat');
    final sem = _refList('semester');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Pilih Tingkat
          _buildDropdown(
            items: tingkat,
            value: _filterTingkat,
            hint: 'Pilih Tingkat',
            width: 150,
            onChanged: (v) {
              setState(() {
                _filterTingkat = v;
                _jadwal = [];
              });
              _loadJadwal();
            },
          ),
          const SizedBox(width: 12),
          // Genre Jadwal
          _buildGenreDropdown(),
          const SizedBox(width: 12),
          // Semester
          _buildDropdown(
            items: sem,
            value: _filterSemester,
            hint: 'Semester',
            width: 180,
            onChanged: (v) {
              setState(() => _filterSemester = v);
              _loadJadwal();
            },
          ),
          const SizedBox(width: 12),
          // Hari
          _buildHariDropdown(),
          const Spacer(),
          // Reset
          _buildActionBtn(
            icon: Icons.undo,
            label: 'Reset',
            color: Colors.red,
            onPressed: _resetJadwal,
          ),
          const SizedBox(width: 8),
          // Simpan
          _buildActionBtn(
            icon: Icons.save_outlined,
            label: 'Simpan',
            color: AppTheme.primary,
            onPressed: _simpanJadwal,
          ),
        ],
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterGenre,
          hint: const Text('Genre Jadwal', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          items: _genreList.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _filterGenre = v),
        ),
      ),
    );
  }

  Widget _buildHariDropdown() {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedHari,
          hint: const Text('Hari', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _selectedHari = v),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<Map<String, dynamic>> items,
    required String? value,
    required String hint,
    required double width,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: const TextStyle(fontSize: 13)),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(
              value: '${e['id']}',
              child: Text('${e['nama']}', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // ── Two Column Layout ──

  Widget _buildTwoColumnLayout() {
    return Row(
      children: [
        // Panel Kiri
        SizedBox(width: 280, child: _buildLeftPanel()),
        // Divider
        VerticalDivider(width: 1, color: Colors.grey[200]),
        // Panel Kanan + Panel Bawah
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildTimetable()),
              _buildBentrokPanel(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Panel Kiri ──

  Widget _buildLeftPanel() {
    final guruMapel = _refList('guru_mapel');

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Daftar Kegiatan & Mapel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Kegiatan Tetap
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: const Row(
              children: [
                Text('KEGIATAN TETAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
          ),
          ..._kegiatanTetap.map((k) => _buildKegiatanItem(k)),

          Divider(height: 1, color: Colors.grey[200], indent: 16, endIndent: 16),

          // Daftar Mapel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('DAFTAR MAPEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                const Spacer(),
                Text('${guruMapel.length} mapel', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: guruMapel.length,
              itemBuilder: (_, i) => _buildMapelItem(guruMapel[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanItem(Map<String, dynamic> kegiatan) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'tipe': 'kegiatan',
        'nama': kegiatan['nama'],
        'is_istirahat': kegiatan['tipe'] == 'istirahat',
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(kegiatan['nama'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildKegiatanItemContent(kegiatan)),
      child: _buildKegiatanItemContent(kegiatan),
    );
  }

  Widget _buildKegiatanItemContent(Map<String, dynamic> kegiatan) {
    final isIstirahat = kegiatan['tipe'] == 'istirahat';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isIstirahat ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isIstirahat ? Colors.orange[200]! : Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isIstirahat ? Icons.coffee : Icons.school,
            size: 14,
            color: isIstirahat ? Colors.orange[700] : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kegiatan['nama'],
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isIstirahat ? Colors.orange[800] : Colors.blue[800]),
            ),
          ),
          Icon(Icons.drag_indicator, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildMapelItem(Map<String, dynamic> guruMapel) {
    final namaMapel = guruMapel['mapel_nama']?.toString() ?? guruMapel['nama']?.toString() ?? '-';
    final namaGuru = guruMapel['guru_nama']?.toString() ?? guruMapel['nip']?.toString() ?? '-';

    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'tipe': 'mapel',
        'mata_pelajaran_id': guruMapel['mata_pelajaran_id'] ?? guruMapel['id'],
        'guru_id': guruMapel['guru_id'],
        'mapel_nama': namaMapel,
        'guru_nama': namaGuru,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(namaMapel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(namaGuru, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildMapelItemContent(namaMapel, namaGuru)),
      child: _buildMapelItemContent(namaMapel, namaGuru),
    );
  }

  Widget _buildMapelItemContent(String namaMapel, String namaGuru) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book_outlined, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaMapel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(namaGuru, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // ── Tabel Jadwal (Panel Kanan) ──

  Widget _buildTimetable() {
    if (_selectedHari == null) {
      return _buildEmptyState('Pilih hari terlebih dahulu');
    }

    final kelasFiltered = _filterTingkat != null
        ? _refList('kelas').where((k) => k['tingkat_id'].toString() == _filterTingkat).toList()
        : _refList('kelas');

    if (kelasFiltered.isEmpty) {
      return _buildEmptyState('Tidak ada kelas untuk tingkat ini');
    }

    if (_jadwal.isEmpty) {
      return _buildEmptyState('Belum ada jadwal. Drag mapel dari panel kiri ke tabel.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 8,
          headingRowHeight: 44,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columns: [
            const DataColumn(label: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            ...kelasFiltered.map((k) => DataColumn(
              label: Text('${k['nama']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            )),
          ],
          rows: _jpSlots.map((jp) {
            final jpKode = jp['kode'] as String;
            final jpWaktu = '${jp['mulai']}-${jp['selesai']}';

            return DataRow(cells: [
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JP $jpKode', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(jpWaktu, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                  ],
                ),
              )),
              ...kelasFiltered.map((kelas) {
                final kelasId = kelas['id'].toString();
                final entry = _jadwal.firstWhere(
                  (j) =>
                      j['kelas_id'].toString() == kelasId &&
                      j['hari'] == _selectedHari &&
                      j['jam_mulai'] == jp['mulai'],
                  orElse: () => <String, dynamic>{},
                );

                return DataCell(
                  entry.isNotEmpty
                      ? _buildScheduleCell(entry)
                      : DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) => _moveToSlot(details.data, kelasId, jp),
                          builder: (ctx, candidates, rejected) => Container(
                            height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[200]!, width: 0.5),
                              color: candidates.isNotEmpty ? Colors.blue[50] : null,
                            ),
                          ),
                        ),
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
      childWhenDragging: Container(
        height: 52,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), color: Colors.grey[100]),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mapelNama, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color[800]), overflow: TextOverflow.ellipsis),
            Text(guruNama, style: TextStyle(fontSize: 9, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Panel Bawah: Keterangan Jam Bentrok ──

  Widget _buildBentrokPanel() {
    final bentrok = _detectBentrok();

    return Container(
      height: bentrok.isEmpty ? 60 : 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bentrok.isEmpty ? Colors.grey[50] : Colors.red[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bentrok.isEmpty ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 16,
                color: bentrok.isEmpty ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                bentrok.isEmpty ? 'Tidak ada jam bentrok' : 'Keterangan Jam Bentrok (${bentrok.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: bentrok.isEmpty ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (bentrok.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: bentrok.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${bentrok[i]}',
                    style: TextStyle(fontSize: 11, color: Colors.red[800]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _detectBentrok() {
    if (_jadwal.isEmpty || _selectedHari == null) return [];

    final Map<String, List<Map<String, dynamic>>> guruSchedule = {};

    for (final j in _jadwal) {
      if (j['hari'] != _selectedHari) continue;
      if (j['is_istirahat'] == true) continue;

      final guruId = j['guru_id']?.toString();
      if (guruId == null) continue;

      final jpKey = '${j['jam_mulai']}-${j['jam_selesai']}';
      final kelasNama = j['kelas_nama']?.toString() ?? j['kelas_id']?.toString() ?? '?';
      final mapelNama = j['mapel_nama']?.toString() ?? '-';

      guruSchedule.putIfAbsent(guruId, () => []).add({
        'jp': jpKey,
        'kelas': kelasNama,
        'mapel': mapelNama,
        'guru_nama': j['guru_nama']?.toString() ?? '-',
      });
    }

    final List<String> bentrok = [];
    for (final entry in guruSchedule.entries) {
      final Map<String, List<String>> jpGroups = {};
      for (final s in entry.value) {
        jpGroups.putIfAbsent(s['jp']!, () => []).add('${s['mapel']} (${s['kelas']})');
      }

      for (final jpEntry in jpGroups.entries) {
        if (jpEntry.value.length > 1) {
          final guruNama = entry.value.first['guru_nama'];
          final mapelKelas = jpEntry.value.join(', ');
          bentrok.add('${jpEntry.key}: $guruNama mengajar di $mapelKelas pada jam yang sama');
        }
      }
    }

    return bentrok;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ── Drag & Drop ──

  Future<void> _moveToSlot(Map<String, dynamic> data, String kelasId, Map<String, dynamic> jp) async {
    if (_filterSemester == null) return;

    final tipe = data['tipe'] ?? 'mapel';
    final isIstirahat = data['is_istirahat'] ?? false;

    Map<String, dynamic> body;

    if (tipe == 'kegiatan') {
      body = {
        'kelas_id': int.tryParse(kelasId),
        'mata_pelajaran_id': null,
        'guru_id': null,
        'hari': _selectedHari,
        'jam_mulai': jp['mulai'],
        'jam_selesai': jp['selesai'],
        'semester_id': int.tryParse(_filterSemester!),
        'is_istirahat': isIstirahat,
        'nama_kegiatan': data['nama'],
      };
    } else {
      body = {
        'kelas_id': int.tryParse(kelasId),
        'mata_pelajaran_id': data['mata_pelajaran_id'],
        'guru_id': data['guru_id'],
        'hari': _selectedHari,
        'jam_mulai': jp['mulai'],
        'jam_selesai': jp['selesai'],
        'semester_id': int.tryParse(_filterSemester!),
      };
    }

    try {
      final cek = await WakilKurikulumService.cekBentrok(body);
      if (cek['bentrok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${cek['message']}'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      await WakilKurikulumService.createJadwal(body);
      _loadJadwal();
      if (mounted) {
        final nama = tipe == 'kegiatan' ? data['nama'] : data['mapel_nama'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nama ditambahkan ke $kelasId'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Actions ──

  Future<void> _simpanJadwal() async {
    if (_jadwal.isEmpty) return;
    try {
      final data = _jadwal.map((j) => {
        'id': j['id'] as int,
        'kelas_id': j['kelas_id'] as int,
        'mata_pelajaran_id': j['mata_pelajaran_id'] as int?,
        'guru_id': j['guru_id'] as int?,
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
      }
      _loadJadwal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetJadwal() async {
    if (_filterSemester == null) return;
    final ok = await AppUtils.confirm(context, title: 'Reset Jadwal',
        message: 'Hapus SEMUA jadwal draft semester ini? Jadwal tervalidasi tetap aman.');
    if (!ok) return;

    try {
      await WakilKurikulumService.resetJadwal(int.parse(_filterSemester!));
      _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal direset'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ══════════════════════════════ KESIAPAN MENGAJAR TAB ══════════════════════════════

  Widget _buildKesiapanTab() {
    final sem = _refList('semester');

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _buildDropdown(
            items: sem,
            value: _filterSemester,
            hint: 'Semester',
            width: 200,
            onChanged: (v) {
              setState(() => _filterSemester = v);
              _loadKesiapan();
            },
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _filterSemester != null ? _simpanKesiapan : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Simpan Semua'),
          ),
        ]),
      ),
      Expanded(
        child: _kesiapanLoading
            ? const Center(child: CircularProgressIndicator())
            : _filterSemester == null
                ? _buildEmptyState('Pilih semester terlebih dahulu')
                : _kesiapan.isEmpty
                    ? _buildEmptyState('Belum ada data kesiapan.')
                    : _buildKesiapanTable(),
      ),
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
                onChanged: (v) => setState(() => g.hariAktif = v),
              )),
              DataCell(SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: g.jpMaxPerHari.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder(), isDense: true),
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
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder(), isDense: true),
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
                    child: LinearProgressIndicator(value: persen.clamp(0.0, 1.0), backgroundColor: Colors.grey[200], color: capColor),
                  ),
                  if (persen >= 1.0) Text('Kelebihan ${jpTerisi - jpMaxMinggu} JP', style: const TextStyle(fontSize: 9, color: Colors.red)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kesiapan berhasil disimpan'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
        );
      }
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
      Expanded(
        child: _waliKelasLoading
            ? const Center(child: CircularProgressIndicator())
            : _waliKelas.isEmpty
                ? _buildEmptyState('Belum ada data wali kelas.')
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
                  ),
      ),
    ]);
  }
}

// ══════════════════════════════ DATA CLASSES ══════════════════════════════

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

// ══════════════════════════════ SHARED WIDGETS ══════════════════════════════

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
