import 'package:flutter/material.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../../shared/widgets/dashboard_shell.dart';
import 'dashboard/dashboard_page.dart';
import 'absensi/absensi_page.dart';
import 'jadwal/jadwal_page.dart';
import 'nilai/nilai_page.dart';
import 'rapor/rapor_page.dart';
import 'pengaduan/pengaduan_page.dart';
import 'profil/profil_page.dart';
import 'wali_kelas/wali_kelas_page.dart';
import 'materi/materi_page.dart';
import 'services/guru_service.dart';

class GuruMapelPage extends StatefulWidget {
  const GuruMapelPage({super.key});

  @override
  State<GuruMapelPage> createState() => _GuruMapelPageState();
}

class _GuruMapelPageState extends State<GuruMapelPage> {
  bool _isWaliKelas = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wali = await GuruService.cekWaliKelas();
      if (mounted) _isWaliKelas = wali['is_wali_kelas'] == true;
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat status wali kelas');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Asatidz',
      showScanTab: true,
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPageGuru(
        onFeatureTap: onFeatureTap,
      ),
      features: {
        'absensi': (_) => const AbsensiPageGuru(),
        'jadwal': (_) => const JadwalPageGuru(),
        'nilai': (_) => const NilaiPageGuru(),
        'materi': (_) => const MateriPageGuru(),
        if (_isWaliKelas) 'rapor': (_) => const RaporPageGuru(),
        'pengaduan': (_) => const PengaduanPageGuru(),
        if (_isWaliKelas) 'wali-kelas': (_) => const WaliKelasPageGuru(),
        'profil': (_) => const ProfilPageGuru(),
      },
      profilePage: (_) => const ProfilPageGuru(),
    );
  }
}