import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../services/kepala_sekolah_service.dart';

class DaurohNilaiPageKS extends StatefulWidget {
  const DaurohNilaiPageKS({super.key});

  @override
  State<DaurohNilaiPageKS> createState() => _DaurohNilaiPageKSState();
}

class _DaurohNilaiPageKSState extends State<DaurohNilaiPageKS> {
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;

  List<dynamic> _jenjangList = [];
  List<dynamic> _kelasList = [];
  List<dynamic> _programList = [];

  String? _selectedJenjang;
  String? _selectedKelasId;
  String? _selectedProgramId;
  final _searchCtrl = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final res = await KepalaSekolahService.getDaurohFilters();
      if (mounted) {
        setState(() {
          _jenjangList = (res['jenjang'] as List?) ?? [];
          _kelasList = (res['kelas'] as List?) ?? [];
          _programList = (res['program'] as List?) ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await KepalaSekolahService.getDaurohNilai(
        page: _currentPage,
        jenjang: _selectedJenjang,
        kelasId: _selectedKelasId,
        programId: _selectedProgramId,
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _summary = (res['summary'] as Map<String, dynamic>?) ?? {};
          _totalPages = res['pagination']?['total_pages'] ?? 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() => _currentPage = 1);
    _loadData();
  }

  void _resetFilter() {
    setState(() {
      _selectedJenjang = null;
      _selectedKelasId = null;
      _selectedProgramId = null;
      _searchCtrl.clear();
      _currentPage = 1;
    });
    _loadData();
  }

  Future<void> _printPreview() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Monitoring Nilai Dauroh', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Dicetak: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            if (_selectedJenjang != null || _selectedKelasId != null || _selectedProgramId != null)
              pw.Text(
                'Filter: ${_selectedJenjang ?? "Semua Jenjang"} | ${_getKelasName(_selectedKelasId)} | ${_getProgramName(_selectedProgramId)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 24,
            headers: ['No', 'Nama', 'NIS', 'Kelas', 'Program', 'Jenis', 'Hafalan', 'Bacaan'],
            data: _items.asMap().entries.map((e) {
              final i = e.key + 1;
              final item = e.value;
              return [
                '$i',
                item['nama_santri']?.toString() ?? '-',
                item['nis']?.toString() ?? '-',
                item['kelas_nama']?.toString() ?? '-',
                item['nama_program']?.toString() ?? '-',
                item['jenis_dauroh']?.toString() ?? '-',
                item['nilai_hafalan']?.toString() ?? '-',
                item['nilai_bacaan']?.toString() ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save(), name: 'Monitoring_Nilai_Dauroh');
  }

  String _getKelasName(String? id) {
    if (id == null) return 'Semua Kelas';
    final kelas = _kelasList.firstWhere((k) => k['id'].toString() == id, orElse: () => null);
    return kelas?['nama']?.toString() ?? 'Semua Kelas';
  }

  String _getProgramName(String? id) {
    if (id == null) return 'Semua Program';
    final prog = _programList.firstWhere((p) => p['id'].toString() == id, orElse: () => null);
    return prog?['nama_program']?.toString() ?? 'Semua Program';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Monitoring Nilai Dauroh'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak / Print Preview',
            onPressed: _items.isEmpty ? null : _printPreview,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildSummarySection(),
          Expanded(child: _buildDataTable()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.grey800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedJenjang,
                  decoration: InputDecoration(
                    labelText: 'Jenjang',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Jenjang')),
                    ..._jenjangList.map((j) => DropdownMenuItem(
                      value: j['nama']?.toString(),
                      child: Text(j['nama']?.toString() ?? ''),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedJenjang = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedKelasId,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                    ..._kelasList.map((k) => DropdownMenuItem(
                      value: k['id']?.toString(),
                      child: Text(k['nama']?.toString() ?? ''),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedKelasId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProgramId,
                  decoration: InputDecoration(
                    labelText: 'Program',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Program')),
                    ..._programList.map((p) => DropdownMenuItem(
                      value: p['id']?.toString(),
                      child: Text(p['nama_program']?.toString() ?? ''),
                    )),
                  ],
                  onChanged: (v) => setState(() => _selectedProgramId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama / NIS...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildSummaryCard('Total Santri', '${_summary['total_santri'] ?? 0}', AppTheme.blue),
          const SizedBox(width: 12),
          _buildSummaryCard('Rata Hafalan', '${_summary['rata_hafalan'] ?? 0}', AppTheme.primary),
          const SizedBox(width: 12),
          _buildSummaryCard('Rata Bacaan', '${_summary['rata_bacaan'] ?? 0}', AppTheme.orange),
          const SizedBox(width: 12),
          _buildSummaryCard('Sudah Dinilai', '${_summary['sudah_dinilai'] ?? 0}', Colors.green),
          const SizedBox(width: 12),
          _buildSummaryCard('Belum Dinilai', '${_summary['belum_dinilai'] ?? 0}', AppTheme.red),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.grey600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.grey400),
            const SizedBox(height: 16),
            Text('Tidak ada data nilai dauroh', style: TextStyle(fontSize: 16, color: AppTheme.grey500)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primary.withAlpha(25)),
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Hafalan', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Bacaan', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _items.asMap().entries.map((e) {
            final i = e.key + 1;
            final item = e.value;
            final hafalan = item['nilai_hafalan'];
            final bacaan = item['nilai_bacaan'];

            return DataRow(cells: [
              DataCell(Text('$i', style: const TextStyle(fontSize: 13))),
              DataCell(Text(item['nama_santri']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
              DataCell(Text(item['nis']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
              DataCell(Text(item['kelas_nama']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
              DataCell(Text(item['nama_program']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (item['jenis_dauroh']?.toString() == 'hafalan' ? AppTheme.primary : AppTheme.orange).withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['jenis_dauroh']?.toString() ?? '-',
                    style: TextStyle(fontSize: 12, color: item['jenis_dauroh']?.toString() == 'hafalan' ? AppTheme.primary : AppTheme.orange),
                  ),
                ),
              ),
              DataCell(Text(
                hafalan != null ? hafalan.toString() : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hafalan != null ? FontWeight.bold : FontWeight.normal,
                  color: hafalan != null ? AppTheme.primary : AppTheme.grey400,
                ),
              )),
              DataCell(Text(
                bacaan != null ? bacaan.toString() : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bacaan != null ? FontWeight.bold : FontWeight.normal,
                  color: bacaan != null ? AppTheme.primary : AppTheme.grey400,
                ),
              )),
              DataCell(
                SizedBox(
                  width: 120,
                  child: Text(
                    item['catatan']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
            child: const Text('Sebelumnya'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Halaman $_currentPage / $_totalPages', style: TextStyle(color: AppTheme.grey700)),
          ),
          OutlinedButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }
}