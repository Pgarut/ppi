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
    return _loading
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
                _buildSectionTitle('Riwayat Penilaian'),
                const SizedBox(height: 12),
                if (_nilai.isEmpty)
                  _buildEmptyCard('Belum ada penilaian')
                else
                  ..._nilai.map((n) => _buildNilaiCard(n)),
              ],
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
            style: const TextStyle(color: AppTheme.grey500, fontSize: 14),
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

  Widget _buildNilaiCard(Map<String, dynamic> nilai) {
    final program = nilai['nama_program']?.toString() ?? '-';
    final surat = nilai['surat_nama']?.toString() ?? '-';
    final dariAyat = nilai['dari_ayat']?.toString() ?? '-';
    final sampaiAyat = nilai['sampai_ayat']?.toString() ?? '-';
    final status = nilai['status_hafalan']?.toString() ?? '-';
    final totalNilai = nilai['total_nilai'];
    final bidang1 = nilai['nilai_bidang1'];
    final bidang2 = nilai['nilai_bidang2'];
    final bidang3 = nilai['nilai_bidang3'];
    final catatan = nilai['catatan_umum']?.toString();
    final musyrifah = nilai['musyrifah_nama']?.toString() ?? '-';
    final tanggal = nilai['created_at']?.toString() ?? '-';

    // Status color
    Color statusColor;
    switch (status) {
      case 'mengulang':
        statusColor = AppTheme.orange;
        break;
      case 'melanjutkan':
        statusColor = AppTheme.primary;
        break;
      case 'selesai':
        statusColor = Colors.green;
        break;
      default:
        statusColor = AppTheme.grey500;
    }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program: $program',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surat: $surat (Ayat $dariAyat-$sampaiAyat)',
                        style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildNilaiChip('Bidang 1', bidang1, 40),
                const SizedBox(width: 8),
                _buildNilaiChip('Bidang 2', bidang2, 30),
                const SizedBox(width: 8),
                _buildNilaiChip('Bidang 3', bidang3, 30),
                const Spacer(),
                _buildTotalNilai(totalNilai),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppTheme.grey500),
                const SizedBox(width: 4),
                Text(
                  'Dinilai oleh: $musyrifah',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.grey500),
                const SizedBox(width: 4),
                Text(
                  tanggal.length > 10 ? tanggal.substring(0, 10) : tanggal,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
              ],
            ),
            if (catatan != null && catatan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.grey50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catatan,
                      style: const TextStyle(fontSize: 12, color: AppTheme.grey700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNilaiChip(String label, dynamic nilai, int max) {
    final nilaiNum = nilai != null ? (nilai as num).toDouble() : null;
    Color color = AppTheme.grey600;
    if (nilaiNum != null) {
      final percentage = (nilaiNum / max) * 100;
      if (percentage >= 80) {
        color = AppTheme.primary;
      } else if (percentage >= 60) {
        color = AppTheme.orange;
      } else {
        color = AppTheme.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            nilaiNum?.toStringAsFixed(0) ?? '-',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            '/ $max',
            style: TextStyle(fontSize: 10, color: color.withAlpha(150)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNilai(dynamic nilai) {
    final nilaiNum = nilai != null ? (nilai as num).toDouble() : null;
    Color color = AppTheme.grey600;
    if (nilaiNum != null) {
      if (nilaiNum >= 80) {
        color = AppTheme.primary;
      } else if (nilaiNum >= 60) {
        color = AppTheme.orange;
      } else {
        color = AppTheme.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            nilaiNum?.toStringAsFixed(0) ?? '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}