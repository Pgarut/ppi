import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/kepala_sekolah_service.dart';

class DashboardPageKS extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  final VoidCallback? onLogout;
  const DashboardPageKS({super.key, this.onFeatureTap, this.onLogout});

  @override
  State<DashboardPageKS> createState() => _DashboardPageKSState();
}

class _DashboardPageKSState extends State<DashboardPageKS> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _data = await KepalaSekolahService.getDashboard();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data?['statistik'] as Map<String, dynamic>? ?? {};

    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.people_outline, 'Santri Aktif', '${stats['total_siswa'] ?? 0}', const Color(0xFF2E7D32)),
        StatItem(Icons.school_outlined, 'Asatidz', '${stats['total_guru'] ?? 0}', const Color(0xFF43A047)),
        StatItem(Icons.meeting_room_outlined, 'Kelas', '${stats['total_kelas'] ?? 0}', const Color(0xFF66BB6A)),
        StatItem(Icons.book_outlined, 'Mapel', '${stats['total_mapel'] ?? 0}', const Color(0xFFF9A825)),
      ],
      features: const [
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate & unduh laporan', Color(0xFF2E7D32)),
        FeatureItem('Monitoring', 'monitoring', Icons.trending_up_outlined, 'Pantau aktivitas sekolah', Color(0xFF43A047)),
      ],
      onFeatureTap: widget.onFeatureTap,
      onLogout: widget.onLogout,
    );
  }
}