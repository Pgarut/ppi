import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import 'dashboard/dashboard_santri_page.dart';
import 'jadwal/jadwal_santri_page.dart';
import 'absensi/absensi_santri_page.dart';
import 'nilai/nilai_santri_page.dart';
import 'materi/materi_santri_page.dart';
import 'dauroh/dauroh_santri_page.dart';
import 'profil/profil_santri_page.dart';

class SantriPage extends StatelessWidget {
  const SantriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Santri',
      dashboardBuilder: (context, onFeatureTap, onLogout) {
        return DashboardSantriPage(onFeatureTap: onFeatureTap);
      },
      features: {
        'jadwal': (_) => const JadwalSantriPage(),
        'absensi': (_) => const AbsensiSantriPage(),
        'nilai': (_) => const NilaiSantriPage(),
        'materi': (_) => const MateriSantriPage(),
        'dauroh': (_) => const DaurohSantriPage(),
      },
      profilePage: (_) => const ProfilSantriPage(),
    );
  }
}
