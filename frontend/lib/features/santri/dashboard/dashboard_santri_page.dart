import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_template.dart';
import '../services/santri_service.dart';
import '../services/dauroh_santri_service.dart';

class DashboardSantriPage extends StatefulWidget {
  final void Function(String) onFeatureTap;

  const DashboardSantriPage({super.key, required this.onFeatureTap});

  @override
  State<DashboardSantriPage> createState() => _DashboardSantriPageState();
}

class _DashboardSantriPageState extends State<DashboardSantriPage> {
  final _service = SantriService();
  final _daurohService = DaurohSantriService();
  List<Map<String, dynamic>> _jadwalHariIni = [];
  int _totalHadir = 0;
  int _totalAbsensi = 0;
  double _rataRataNilai = 0;
  int _totalProgramDauroh = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      const hariNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final hariIni = hariNames[DateTime.now().weekday % 7];
      final now = DateTime.now();
      final bulan = now.month.toString();
      final tahun = now.year.toString();

      final results = await Future.wait([
        _service.getJadwal(hari: hariIni),
        _service.getAbsensi(bulan: bulan, tahun: tahun),
        _service.getNilai(),
        _daurohService.getProgram(),
      ]);

      final absensiData = (results[1]['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final nilaiData = results[2] as Map<String, dynamic>;

      int hadir = 0;
      for (final a in absensiData) {
        if (a['status'] == 'hadir') hadir++;
      }

      if (mounted) {
        setState(() {
          _jadwalHariIni = results[0];
          _totalAbsensi = absensiData.length;
          _totalHadir = hadir;
          _rataRataNilai = (nilaiData['rata_rata_keseluruhan'] as num?)?.toDouble() ?? 0;
          _totalProgramDauroh = results[3].length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.schedule, 'Jadwal Hari Ini', '${_jadwalHariIni.length} Mapel', AppTheme.primary),
        StatItem(Icons.how_to_reg, 'Kehadiran', '$_totalHadir dari $_totalAbsensi', Colors.green),
        StatItem(Icons.grade, 'Rata-rata Nilai', _rataRataNilai.toStringAsFixed(1), Colors.orange),
        StatItem(Icons.bookmark, 'Program Dauroh', '$_totalProgramDauroh Program', Colors.purple),
      ],
      features: const [
        FeatureItem('Jadwal', 'jadwal', Icons.calendar_today, 'Lihat jadwal pelajaran'),
        FeatureItem('Absensi', 'absensi', Icons.how_to_reg, 'Riwayat kehadiran'),
        FeatureItem('Nilai', 'nilai', Icons.grade, 'Nilai akademik'),
        FeatureItem('Materi', 'materi', Icons.menu_book, 'Materi pelajaran'),
        FeatureItem('Dauroh', 'dauroh', Icons.bookmark, 'Program Dauroh & Nilai'),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}
