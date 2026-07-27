import 'package:flutter/material.dart';
import '../../shared/widgets/academic_shell.dart';
import 'dashboard/dashboard_page_bk.dart';
import 'pengaduan/pengaduan_page_bk.dart';
import 'laporan/laporan_page_bk.dart';
import 'konseling/konseling_page.dart';
import 'bakat_minat/bakat_minat_page.dart';
import 'monitoring_akademik/monitoring_akademik_page.dart';

class GuruBKPage extends StatefulWidget {
  const GuruBKPage({super.key});

  @override
  State<GuruBKPage> createState() => _GuruBKPageState();
}

class _GuruBKPageState extends State<GuruBKPage> {
  int _currentIndex = 0;

  final _menuItems = [
    NavItem(Icons.dashboard_outlined, 'Dashboard'),
    NavItem(Icons.report_outlined, 'Pengaduan'),
    NavItem(Icons.support_agent_outlined, 'Konseling'),
    NavItem(Icons.psychology_outlined, 'Bakat-Minat'),
    NavItem(Icons.trending_up_outlined, 'Monitoring'),
    NavItem(Icons.description_outlined, 'Laporan'),
  ];

  final _pages = const [
    DashboardPageBK(),
    PengaduanPageBK(),
    KonselingPage(),
    BakatMinatPage(),
    MonitoringAkademikPage(),
    LaporanPageBK(),
  ];

  @override
  Widget build(BuildContext context) {
    return AcademicShell(
      title: 'Guru BK',
      currentIndex: _currentIndex,
      onNavigate: (i) => setState(() => _currentIndex = i),
      menuItems: _menuItems,
      child: _pages[_currentIndex],
    );
  }
}
