import 'package:flutter/material.dart';
import '../../shared/widgets/academic_shell.dart';
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
  int _currentIndex = 0;

  final _menuItems = [
    NavItem(Icons.dashboard_outlined, 'Dashboard'),
    NavItem(Icons.checklist_outlined, 'Absensi'),
    NavItem(Icons.calendar_month_outlined, 'Jadwal'),
    NavItem(Icons.grading_outlined, 'Nilai'),
    NavItem(Icons.assignment_outlined, 'Rapor'),
    NavItem(Icons.warning_amber_outlined, 'Pengaduan'),
    NavItem(Icons.people_outlined, 'Wali Kelas'),
    NavItem(Icons.person_outline, 'Profil'),
  ];

  final _pages = const [
    DashboardPageGuru(),
    AbsensiPageGuru(),
    JadwalPageGuru(),
    NilaiPageGuru(),
    RaporPageGuru(),
    PengaduanPageGuru(),
    WaliKelasPageGuru(),
    ProfilPageGuru(),
  ];

  @override
  Widget build(BuildContext context) {
    return AcademicShell(
      title: 'Guru Mapel / Wali Kelas',
      currentIndex: _currentIndex,
      onNavigate: (i) => setState(() => _currentIndex = i),
      menuItems: _menuItems,
      child: _pages[_currentIndex],
    );
  }
}
