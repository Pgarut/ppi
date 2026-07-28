import 'package:flutter/material.dart';
import '../../shared/widgets/dashboard_shell.dart';
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
  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Admin',
      dashboardBuilder: (context, onFeatureTap, onLogout) => DashboardPage(
        onFeatureTap: onFeatureTap,
        onLogout: onLogout,
      ),
      features: {
        'master-data': (_) => const MasterDataPage(),
        'absensi': (_) => const AbsensiPage(),
        'nilai': (_) => const NilaiPage(),
        'rapor': (_) => const RaporPage(),
        'pengaturan': (_) => const PengaturanPage(),
      },
    );
  }
}
