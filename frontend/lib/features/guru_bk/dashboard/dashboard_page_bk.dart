import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/guru_bk_service.dart';

class DashboardPageBK extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  final VoidCallback onLogout;
  const DashboardPageBK({super.key, required this.onFeatureTap, required this.onLogout});

  @override
  State<DashboardPageBK> createState() => _DashboardPageBKState();
}

class _DashboardPageBKState extends State<DashboardPageBK> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _stats = await GuruBKService.getStatistik();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.list_alt, 'Total Pengaduan', '${_stats?['total_pengaduan'] ?? 0}', Colors.blue),
        StatItem(Icons.engineering, 'Aktif Diproses', '${_stats?['aktif_diproses'] ?? 0}', Colors.orange),
        StatItem(Icons.check_circle, 'Selesai', '${_stats?['selesai'] ?? 0}', Colors.green),
        StatItem(Icons.support_agent, 'Total Konseling', '${_stats?['total_konseling'] ?? 0}', Colors.indigo),
      ],
      features: const [
        FeatureItem('Pengaduan', 'pengaduan', Icons.report_outlined, 'Kelola pengaduan siswa', Color(0xFF1B5E20)),
        FeatureItem('Konseling', 'konseling', Icons.support_agent_outlined, 'Jadwal & catatan konseling', Color(0xFF2E7D32)),
        FeatureItem('Bakat & Minat', 'bakat-minat', Icons.psychology_outlined, 'Tes & analisis bakat', Color(0xFF43A047)),
        FeatureItem('Monitoring', 'monitoring', Icons.trending_up_outlined, 'Pantau perkembangan siswa', Color(0xFF66BB6A)),
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan BK', Color(0xFFFDD835)),
      ],
      onFeatureTap: widget.onFeatureTap,
      onLogout: widget.onLogout,
    );
  }
}