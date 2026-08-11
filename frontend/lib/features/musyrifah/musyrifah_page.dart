import 'package:flutter/material.dart';
import '../../shared/widgets/dashboard_shell.dart';
import 'dashboard/dashboard_musyrifah_page.dart';
import 'jadwal/jadwal_dauroh_page.dart';
import 'absensi/scan_qr_musyrifah_page.dart';
import 'absensi/riwayat_absensi_page.dart';
import 'nilai/nilai_dauroh_page.dart';
import 'profil/profil_musyrifah_page.dart';

class MusyrifahPage extends StatelessWidget {
  const MusyrifahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Musyrifah',
      showScanTab: true,
      scanPageBuilder: (context, onBack) => ScanQrMusyrifahPage(onBack: onBack),
      dashboardBuilder: (context, onFeatureTap, onLogout) {
        return DashboardMusyrifahPage(onFeatureTap: onFeatureTap);
      },
      features: {
        'jadwal': (_) => const JadwalDaurohPage(),
        'scan-qr': (_) => const ScanQrMusyrifahPage(),
        'riwayat': (_) => const RiwayatAbsensiPage(),
        'nilai': (_) => const NilaiDaurohPage(),
      },
      profilePage: (_) => const ProfilMusyrifahPage(),
    );
  }
}
