import 'package:flutter/material.dart';
import '../../shared/widgets/academic_shell.dart';
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
  int _currentIndex = 0;

  final _menuItems = [
    NavItem(Icons.dashboard_outlined, 'Dashboard'),
    NavItem(Icons.checklist_outlined, 'Absensi'),
    NavItem(Icons.calendar_month_outlined, 'Penjadwalan'),
    NavItem(Icons.grading_outlined, 'Nilai'),
    NavItem(Icons.trending_up_outlined, 'Kenaikan Kelas'),
    NavItem(Icons.description_outlined, 'Laporan'),
  ];

  final _pages = const [
    DashboardPageWK(),
    AbsensiPageWK(),
    PenjadwalanPage(),
    NilaiPageWK(),
    KenaikanKelasPage(),
    LaporanPageWK(),
  ];

  @override
  Widget build(BuildContext context) {
    return AcademicShell(
      title: 'Wakil Kurikulum',
      currentIndex: _currentIndex,
      onNavigate: (i) => setState(() => _currentIndex = i),
      menuItems: _menuItems,
      child: _pages[_currentIndex],
    );
  }
}
