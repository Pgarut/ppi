import 'package:flutter/material.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import 'dashboard/dashboard_page.dart';
import 'absensi/absensi_page.dart';
import 'jadwal/jadwal_page.dart';
import 'nilai/nilai_page.dart';
import 'rapor/rapor_page.dart';
import 'pengaduan/pengaduan_page.dart';
import 'profil/profil_page.dart';
import 'wali_kelas/wali_kelas_page.dart';

class GuruMapelPage extends StatefulWidget {
  const GuruMapelPage({super.key});

  @override
  State<GuruMapelPage> createState() => _GuruMapelPageState();
}

class _GuruMapelPageState extends State<GuruMapelPage> {
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Guru',
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageGuru(
        onFeatureTap: onFeatureTap,
        onLogout: onLogout,
      ),
      features: {
        'absensi': (_) => const AbsensiPageGuru(),
        'jadwal': (_) => const JadwalPageGuru(),
        'nilai': (_) => const NilaiPageGuru(),
        'rapor': (_) => const RaporPageGuru(),
        'pengaduan': (_) => const PengaduanPageGuru(),
        'wali-kelas': (_) => const WaliKelasPageGuru(),
        'profil': (_) => const ProfilPageGuru(),
      },
      profilePage: (_) => const ProfilPageGuru(),
    );
  }
}