import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../services/dauroh_service.dart';

class AbsensiMonitoringPage extends StatefulWidget {
  const AbsensiMonitoringPage({super.key});

  @override
  State<AbsensiMonitoringPage> createState() => _AbsensiMonitoringPageState();
}

class _AbsensiMonitoringPageState extends State<AbsensiMonitoringPage> {
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _rekap;
  bool _loading = true;
  String? _error;
  String _tanggal = '';
  String? _programId;
  List<Map<String, dynamic>> _programList = [];
  late final TextEditingController _tanggalCtrl;

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now().toIso8601String().split('T')[0];
    _tanggalCtrl = TextEditingController(text: _tanggal);
    _loadPrograms();
    _load();
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    try {
      final res = await DaurohService.listProgram(perPage: 100);
      if (mounted) {
        setState(() {
          _programList = (res['items'] as List).cast<Map<String, dynamic>>();
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
      final res = await DaurohService.monitoringAbsensi(
        tanggal: _tanggal,
        programId: _programId,
      );
      if (mounted) {
        setState(() {
          _data = (res['data'] as List).cast<Map<String, dynamic>>();
          _rekap = res['rekap'] as Map<String, dynamic>?;
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
            'Monitoring Absensi Musyrifah',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          if (_rekap != null) _buildRekap(),
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
          width: 200,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Tanggal',
              prefixIcon: Icon(Icons.calendar_today, size: 18),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            controller: _tanggalCtrl,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_tanggal) ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _tanggal = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  _tanggalCtrl.text = _tanggal;
                });
                _load();
              }
            },
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
                hint: const Text('Semua Program', style: TextStyle(fontSize: 13)),
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

  Widget _buildRekap() {
    final r = _rekap!;
    return Row(
      children: [
        StatChip(label: 'Total', value: '${r['total'] ?? 0}', color: AppTheme.grey600),
        const SizedBox(width: 8),
        StatChip(label: 'Hadir', value: '${r['hadir'] ?? 0}', color: AppTheme.primary),
        const SizedBox(width: 8),
        StatChip(label: 'Izin', value: '${r['izin'] ?? 0}', color: AppTheme.orange),
        const SizedBox(width: 8),
        StatChip(label: 'Sakit', value: '${r['sakit'] ?? 0}', color: AppTheme.blue),
        const SizedBox(width: 8),
        StatChip(label: 'Alpha', value: '${r['alpha'] ?? 0}', color: AppTheme.error),
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
        icon: Icons.checklist_outlined,
        message: 'Belum ada data absensi musyrifah untuk tanggal ini',
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
            DataColumn(label: Text('NIPMUS')),
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('JK')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Hari')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Status')),
          ],
          rows: _data.map((row) {
            final status = row['status']?.toString() ?? 'hadir';
            return DataRow(cells: [
              DataCell(Text(row['nipmus']?.toString() ?? '-')),
              DataCell(Text(row['nama']?.toString() ?? '-')),
              DataCell(Text(row['jenis_kelamin']?.toString() == 'L' ? 'L' : 'P')),
              DataCell(Text(row['nama_program']?.toString() ?? '-')),
              DataCell(Text(row['hari']?.toString() ?? '-')),
              DataCell(Text(row['waktu_masuk']?.toString() ?? '-')),
              DataCell(Text(row['waktu_keluar']?.toString() ?? '-')),
              DataCell(AttendanceStatus.fromString(status)),
            ]);
          }).toList(),
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.grey700),
          dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.grey700),
          columnSpacing: 24,
          horizontalMargin: 20,
        ),
      ),
    );
  }
}
