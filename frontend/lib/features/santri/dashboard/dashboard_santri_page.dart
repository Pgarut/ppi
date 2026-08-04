import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_template.dart';
import '../services/santri_service.dart';

class DashboardSantriPage extends StatefulWidget {
  final void Function(String) onFeatureTap;

  const DashboardSantriPage({super.key, required this.onFeatureTap});

  @override
  State<DashboardSantriPage> createState() => _DashboardSantriPageState();
}

class _DashboardSantriPageState extends State<DashboardSantriPage> {
  final _service = SantriService();
  List<Map<String, dynamic>> _jadwalHariIni = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jadwal = await _service.getJadwal();
      if (mounted) {
        setState(() {
          _jadwalHariIni = jadwal;
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
        const Icon(Icons.schedule, size: 24), 'Jadwal Hari Ini', '${_jadwalHariIni.length} Mapel', AppTheme.primary,
      ].cast<StatItem>(),
      features: const [
        FeatureItem('Jadwal', 'jadwal', Icons.calendar_today, 'Lihat jadwal pelajaran'),
        FeatureItem('Absensi', 'absensi', Icons.how_to_reg, 'Riwayat kehadiran'),
        FeatureItem('Nilai', 'nilai', Icons.grade, 'Nilai akademik'),
        FeatureItem('Materi', 'materi', Icons.menu_book, 'Materi pelajaran'),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}
