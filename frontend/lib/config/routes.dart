import 'package:flutter/material.dart';
import '../features/admin/admin_page.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/wakil_kurikulum/wakil_kurikulum_page.dart';
import '../features/guru_mapel_wali_kelas/guru_mapel_page.dart';
import '../features/guru_bk/guru_bk_page.dart';
import '../features/kepala_sekolah/kepala_sekolah_page.dart';
import '../features/santri/santri_page.dart';
import '../features/musyrifah/musyrifah_page.dart';
import '../shared/widgets/pages/live_display_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String admin = '/admin';
  static const String kepalaSekolah = '/kepala-sekolah';
  static const String wakilKurikulum = '/wakil-kurikulum';
  static const String guru = '/guru';
  static const String guruBk = '/guru-bk';
  static const String santri = '/santri';
  static const String musyrifah = '/musyrifah';
  static const String displayAbsensi = '/display-absensi';

  static String dashboardByRole(String role) {
    switch (role) {
      case 'admin':
        return admin;
      case 'kepala_sekolah':
        return kepalaSekolah;
      case 'wakil_kurikulum':
        return wakilKurikulum;
      case 'guru_mapel_wali_kelas':
        return guru;
      case 'guru_bk':
        return guruBk;
      case 'siswa':
        return santri;
      case 'musyrifah':
        return musyrifah;
      default:
        return login;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminPage());
      case wakilKurikulum:
        return MaterialPageRoute(builder: (_) => const WakilKurikulumPage());
      case guru:
        return MaterialPageRoute(builder: (_) => const GuruMapelPage());
      case guruBk:
        return MaterialPageRoute(builder: (_) => const GuruBKPage());
      case kepalaSekolah:
        return MaterialPageRoute(builder: (_) => const KepalaSekolahPage());
      case santri:
        return MaterialPageRoute(builder: (_) => const SantriPage());
      case musyrifah:
        return MaterialPageRoute(builder: (_) => const MusyrifahPage());
      case displayAbsensi:
        return MaterialPageRoute(builder: (_) => const LiveDisplayPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
