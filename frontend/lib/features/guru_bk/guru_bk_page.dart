import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/pages/profil_page.dart';
import 'dashboard/dashboard_page_bk.dart';
import 'pengaduan/pengaduan_page_bk.dart';
import 'laporan/laporan_page_bk.dart';
import 'konseling/konseling_page.dart';
import 'bakat_minat/bakat_minat_page.dart';
import 'monitoring_akademik/monitoring_akademik_page.dart';

class GuruBKPage extends StatefulWidget {
  const GuruBKPage({super.key});

  @override
  State<GuruBKPage> createState() => _GuruBKPageState();
}

class _GuruBKPageState extends State<GuruBKPage> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'BK',
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageBK(
        onFeatureTap: onFeatureTap,
        onLogout: onLogout,
      ),
      features: {
        'pengaduan': (_) => const PengaduanPageBK(),
        'konseling': (_) => const KonselingPage(),
        'bakat-minat': (_) => const BakatMinatPage(),
        'monitoring': (_) => const MonitoringAkademikPage(),
        'laporan': (_) => const LaporanPageBK(),
      },
      profilePage: (_) => const ProfilPage(),
    );
  }
}