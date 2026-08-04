import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/pages/profil_page.dart';
import 'dashboard/dashboard_page.dart';
import 'absensi/absensi_page.dart';
import 'penjadwalan/penjadwalan_page.dart';
import 'nilai/nilai_page.dart';
import 'kenaikan_kelas/kenaikan_kelas_page.dart';
import 'laporan/laporan_page.dart';

class WakilKurikulumPage extends StatefulWidget {
  const WakilKurikulumPage({super.key});

  @override
  State<WakilKurikulumPage> createState() => _WakilKurikulumPageState();
}

class _WakilKurikulumPageState extends State<WakilKurikulumPage> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'WK',
      showScanTab: true,
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageWK(
        onFeatureTap: onFeatureTap,
      ),
      features: {
        'absensi': (_) => const AbsensiPageWK(),
        'penjadwalan': (_) => const PenjadwalanPage(),
        'nilai': (_) => const NilaiPageWK(),
        'kenaikan-kelas': (_) => const KenaikanKelasPage(),
        'laporan': (_) => const LaporanPageWK(),
      },
      profilePage: (_) => const ProfilPage(),
    );
  }
}