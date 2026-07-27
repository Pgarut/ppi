import 'package:flutter/material.dart';
import 'admin_shell.dart';
import 'dashboard/dashboard_page.dart';
import 'master_data/master_data_page.dart';
import 'absensi/absensi_page.dart';
import 'nilai/nilai_page.dart';
import 'rapor/rapor_page.dart';
import 'pengaturan/pengaturan_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardPage(),
    MasterDataPage(),
    AbsensiPage(),
    NilaiPage(),
    RaporPage(),
    PengaturanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentIndex: _currentIndex,
      onNavigate: (index) => setState(() => _currentIndex = index),
      child: _pages[_currentIndex],
    );
  }
}
