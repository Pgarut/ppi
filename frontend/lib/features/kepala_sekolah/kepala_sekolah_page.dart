import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import '../../../shared/widgets/pages/profil_page.dart';
import 'dashboard/dashboard_page_ks.dart';
import 'jadwal/jadwal_page_ks.dart';
import 'absensi/absensi_page_ks.dart';
import 'nilai/nilai_page_ks.dart';
import 'rapor/rapor_page_ks.dart';
import 'laporan/laporan_page_ks.dart';
import 'bk/bk_page_ks.dart';
import 'dauroh/dauroh_nilai_page_ks.dart';

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
      showScanTab: true,
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageKS(
        onFeatureTap: onFeatureTap,
      ),
      features: {
        'jadwal': (_) => const JadwalPageKS(),
        'absensi': (_) => const AbsensiPageKS(),
        'nilai': (_) => const NilaiPageKS(),
        'rapor': (_) => const RaporPageKS(),
        'dauroh': (_) => const DaurohNilaiPageKS(),
        'laporan': (_) => const LaporanPageKS(),
        'monitoring': (_) => const BKPageKS(),
      },
      profilePage: (_) => const ProfilPage(),
    );
  }
}