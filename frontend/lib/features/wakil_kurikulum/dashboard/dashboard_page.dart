import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/wakil_kurikulum_service.dart';

class DashboardPageWK extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  final VoidCallback onLogout;
  const DashboardPageWK({super.key, required this.onFeatureTap, required this.onLogout});

  @override
  State<DashboardPageWK> createState() => _DashboardPageWKState();
}

class _DashboardPageWKState extends State<DashboardPageWK> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await WakilKurikulumService.getDashboard(); }
    catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.calendar_month_outlined, 'Jadwal', '${_data?['jadwal'] ?? 0}', Colors.blue),
        StatItem(Icons.grading_outlined, 'Total Nilai', '${_data?['total_nilai'] ?? 0}', Colors.green),
        StatItem(Icons.pending_outlined, 'Nilai Draft', '${_data?['nilai_belum_divalidasi'] ?? 0}', Colors.orange),
      ],
      features: const [
        FeatureItem('Absensi', 'absensi', Icons.checklist_outlined, 'Rekap kehadiran siswa & guru'),
        FeatureItem('Penjadwalan', 'penjadwalan', Icons.calendar_month_outlined, 'Atur jadwal pelajaran'),
        FeatureItem('Nilai', 'nilai', Icons.grading_outlined, 'Validasi & kelola nilai'),
        FeatureItem('Kenaikan Kelas', 'kenaikan-kelas', Icons.trending_up_outlined, 'Proses kenaikan kelas'),
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan akademik', isSecondary: true),
      ],
      onFeatureTap: widget.onFeatureTap,
      onLogout: widget.onLogout,
    );
  }
}