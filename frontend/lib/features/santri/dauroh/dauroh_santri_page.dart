import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/dauroh_santri_service.dart';

class DaurohSantriPage extends StatefulWidget {
  const DaurohSantriPage({super.key});

  @override
  State<DaurohSantriPage> createState() => _DaurohSantriPageState();
}

class _DaurohSantriPageState extends State<DaurohSantriPage> {
  final _service = DaurohSantriService();
  List<Map<String, dynamic>> _program = [];
  List<Map<String, dynamic>> _nilai = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _service.getProgram(),
        _service.getNilai(),
      ]);
      if (mounted) {
        setState(() {
          _program = results[0];
          _nilai = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dauroh'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Program Yang Diikuti'),
                  const SizedBox(height: 12),
                  if (_program.isEmpty)
                    _buildEmptyCard('Belum terdaftar di program Dauroh')
                  else
                    ..._program.map((p) => _buildProgramCard(p)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Nilai Dauroh'),
                  const SizedBox(height: 12),
                  if (_nilai.isEmpty)
                    _buildEmptyCard('Belum ada nilai')
                  else
                    _buildNilaiTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.grey800,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(        color: AppTheme.grey500, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final nama = program['nama_program']?.toString() ?? '-';
    final jenis = program['jenis_program']?.toString() ?? '-';
    final dauroh = program['jenis_dauroh']?.toString() ?? '-';
    final hari = program['hari']?.toString() ?? '-';
    final jamMulai = program['jam_mulai']?.toString() ?? '';
    final jamSelesai = program['jam_selesai']?.toString() ?? '';
    final musyrifah = program['musyrifah_nama']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jenis.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dauroh.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, '$hari, $jamMulai - $jamSelesai'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.person, 'Musyrifah: $musyrifah'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.grey500),
          ),
        ),
      ],
    );
  }

  Widget _buildNilaiTable() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(AppTheme.primary.withAlpha(25)),
          columns: const [
            DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Hafalan', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Bacaan', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _nilai.map((n) {
            final nama = n['nama_program']?.toString() ?? '-';
            final jenis = n['jenis_dauroh']?.toString() ?? '-';
            final hafalan = n['nilai_hafalan'];
            final bacaan = n['nilai_bacaan'];
            final catatan = n['catatan']?.toString() ?? '-';

            return DataRow(cells: [
              DataCell(Text(nama, style: const TextStyle(fontSize: 13))),
              DataCell(Text(jenis, style: const TextStyle(fontSize: 13))),
              DataCell(Text(
                hafalan != null ? hafalan.toString() : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hafalan != null ? FontWeight.bold : FontWeight.normal,
                  color: hafalan != null ? AppTheme.primary : AppTheme.grey500,
                ),
              )),
              DataCell(Text(
                bacaan != null ? bacaan.toString() : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bacaan != null ? FontWeight.bold : FontWeight.normal,
                  color: bacaan != null ? AppTheme.primary : AppTheme.grey500,
                ),
              )),
              DataCell(Text(catatan, style: const TextStyle(fontSize: 13))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}