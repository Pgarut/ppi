import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../services/dauroh_service.dart';

class NilaiMonitoringPage extends StatefulWidget {
  const NilaiMonitoringPage({super.key});

  @override
  State<NilaiMonitoringPage> createState() => _NilaiMonitoringPageState();
}

class _NilaiMonitoringPageState extends State<NilaiMonitoringPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  String? _jenjang;
  String? _kelasId;
  String? _programId;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _programList = [];

  @override
  void initState() {
    super.initState();
    _loadReferensi();
    _load();
  }

  Future<void> _loadReferensi() async {
    try {
      final results = await Future.wait([
        DaurohService.listProgram(perPage: 100),
        DaurohService.getReferensi(),
      ]);
      if (mounted) {
        setState(() {
          _programList = (results[0]['items'] as List).cast<Map<String, dynamic>>();
          _kelasList = (results[1]['kelas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DaurohService.monitoringNilai(
        jenjang: _jenjang,
        kelasId: _kelasId,
        programId: _programId,
      );
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitoring Nilai Dauroh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return FilterCard(
      children: [
        SizedBox(
          width: 140,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _jenjang,
                hint: const Text('Jenjang', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Jenjang')),
                  DropdownMenuItem(value: 'MTs', child: Text('MTs')),
                  DropdownMenuItem(value: 'MA', child: Text('MA')),
                ],
                onChanged: (v) {
                  setState(() => _jenjang = v);
                  _load();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _kelasId,
                hint: const Text('Kelas', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                  ..._kelasList.map((k) => DropdownMenuItem(
                    value: '${k['id']}',
                    child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _kelasId = v);
                  _load();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _programId,
                hint: const Text('Program', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Program')),
                  ..._programList.map((p) => DropdownMenuItem(
                    value: '${p['id']}',
                    child: Text(p['nama_program']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _programId = v);
                  _load();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_data.isEmpty) {
      return const EmptyState(
        icon: Icons.grading_outlined,
        message: 'Belum ada data nilai dauroh',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NIS')),
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('JK')),
            DataColumn(label: Text('Kelas')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Jenis')),
            DataColumn(label: Text('Hafalan')),
            DataColumn(label: Text('Bacaan')),
            DataColumn(label: Text('Catatan')),
          ],
          rows: _data.map((row) {
            return DataRow(cells: [
              DataCell(Text(row['nis']?.toString() ?? '-')),
              DataCell(Text(row['nama']?.toString() ?? '-')),
              DataCell(Text(row['jenis_kelamin']?.toString() == 'L' ? 'L' : 'P')),
              DataCell(Text(row['kelas_nama']?.toString() ?? '-')),
              DataCell(Text(row['nama_program']?.toString() ?? '-')),
              DataCell(Text(row['jenis_dauroh']?.toString() == 'hafalan' ? 'Hafalan' : 'Bacaan')),
              DataCell(_buildNilaiValue(row['nilai_hafalan'])),
              DataCell(_buildNilaiValue(row['nilai_bacaan'])),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    row['catatan']?.toString() ?? '-',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ]);
          }).toList(),
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.grey700),
          dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.grey700),
          columnSpacing: 20,
          horizontalMargin: 20,
        ),
      ),
    );
  }

  Widget _buildNilaiValue(dynamic value) {
    if (value == null) return const Text('-', style: TextStyle(color: AppTheme.grey400));
    final num = double.tryParse(value.toString());
    if (num == null) return Text(value.toString());
    Color color;
    if (num >= 80) {
      color = AppTheme.primary;
    } else if (num >= 60) {
      color = AppTheme.orange;
    } else {
      color = AppTheme.error;
    }
    return Text(
      num.toStringAsFixed(0),
      style: TextStyle(fontWeight: FontWeight.w600, color: color),
    );
  }
}
