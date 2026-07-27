import 'package:flutter/material.dart';
import '../../shared/widgets/academic_shell.dart';
import 'dashboard/dashboard_page_ks.dart';
import 'jadwal/jadwal_page_ks.dart';
import 'absensi/absensi_page_ks.dart';
import 'nilai/nilai_page_ks.dart';
import 'rapor/rapor_page_ks.dart';
import 'bk/bk_page_ks.dart';
import 'laporan/laporan_page_ks.dart';

class KepalaSekolahPage extends StatefulWidget {
  const KepalaSekolahPage({super.key});

  @override
  State<KepalaSekolahPage> createState() => _KepalaSekolahPageState();
}

class _KepalaSekolahPageState extends State<KepalaSekolahPage> {
  int _currentIndex = 0;

  final _menuItems = [
    NavItem(Icons.dashboard_outlined, 'Dashboard'),
    NavItem(Icons.calendar_month_outlined, 'Jadwal'),
    NavItem(Icons.checklist_outlined, 'Absensi'),
    NavItem(Icons.grade_outlined, 'Nilai'),
    NavItem(Icons.assignment_outlined, 'Rapor'),
    NavItem(Icons.psychology_outlined, 'BK'),
    NavItem(Icons.description_outlined, 'Laporan'),
  ];

  final _pages = const [
    DashboardPageKS(),
    JadwalPageKS(),
    AbsensiPageKS(),
    NilaiPageKS(),
    RaporPageKS(),
    BKPageKS(),
    LaporanPageKS(),
  ];

  @override
  Widget build(BuildContext context) {
    return AcademicShell(
      title: 'Kepala Sekolah',
      currentIndex: _currentIndex,
      onNavigate: (i) => setState(() => _currentIndex = i),
      menuItems: _menuItems,
      child: _pages[_currentIndex],
    );
  }
}
