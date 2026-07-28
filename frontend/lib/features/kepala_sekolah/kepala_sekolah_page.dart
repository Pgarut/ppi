import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/pages/profil_page.dart';
import 'dashboard/dashboard_page_ks.dart';
import 'laporan/laporan_page_ks.dart';
import 'bk/bk_page_ks.dart';

class KepalaSekolahPage extends StatefulWidget {
  const KepalaSekolahPage({super.key});

  @override
  State<KepalaSekolahPage> createState() => _KepalaSekolahPageState();
}

class _KepalaSekolahPageState extends State<KepalaSekolahPage> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Kamad',
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageKS(
        onFeatureTap: onFeatureTap,
        onLogout: onLogout,
      ),
      features: {
        'laporan': (_) => const LaporanPageKS(),
        'monitoring': (_) => const BKPageKS(),
      },
      profilePage: (_) => const ProfilPage(),
    );
  }
}