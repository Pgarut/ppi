import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/guru_service.dart';

class DashboardPageGuru extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  final VoidCallback onLogout;
  const DashboardPageGuru({super.key, required this.onFeatureTap, required this.onLogout});

  @override
  State<DashboardPageGuru> createState() => _DashboardPageGuruState();
}

class _DashboardPageGuruState extends State<DashboardPageGuru> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await GuruService.getDashboard();
      if (mounted) setState(() => _stats = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.calendar_today, 'Jadwal Hari Ini', '${_stats?['jadwal_hari_ini'] ?? 0}', Colors.blue),
        StatItem(Icons.checklist, 'Total Absensi', '${_stats?['total_absensi'] ?? 0}', Colors.green),
        StatItem(Icons.grading, 'Total Nilai', '${_stats?['total_nilai'] ?? 0}', Colors.orange),
        StatItem(Icons.warning_amber, 'Pengaduan Aktif', '${_stats?['pengaduan_aktif'] ?? 0}', Colors.red),
      ],
      features: const [
        FeatureItem('Absensi', 'absensi', Icons.checklist_outlined, 'Input & rekap kehadiran', Color(0xFF1B5E20)),
        FeatureItem('Jadwal', 'jadwal', Icons.calendar_month_outlined, 'Lihat jadwal mengajar', Color(0xFF2E7D32)),
        FeatureItem('Nilai', 'nilai', Icons.grading_outlined, 'Input & kelola nilai siswa', Color(0xFF43A047)),
        FeatureItem('Rapor', 'rapor', Icons.assignment_outlined, 'Cetak rapor siswa', Color(0xFF66BB6A)),
        FeatureItem('Pengaduan', 'pengaduan', Icons.warning_amber_outlined, 'Lapor & pantau pengaduan', Color(0xFFFDD835)),
        FeatureItem('Wali Kelas', 'wali-kelas', Icons.people_outlined, 'Kelola data wali kelas', Color(0xFFFFA726)),
      ],
      onFeatureTap: widget.onFeatureTap,
      onLogout: widget.onLogout,
    );
  }
}