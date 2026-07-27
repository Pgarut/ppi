import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'dashboard/dashboard_page_ks.dart';
import 'laporan/laporan_page_ks.dart';
import 'bk/bk_page_ks.dart';

class KepalaSekolahPage extends StatefulWidget {
  const KepalaSekolahPage({super.key});

  @override
  State<KepalaSekolahPage> createState() => _KepalaSekolahPageState();
}

class _KepalaSekolahPageState extends State<KepalaSekolahPage> {
  int _shellTab = 0;
  String? _activeFeature;

  void _openFeature(String feature) {
    setState(() => _activeFeature = feature);
  }

  void _goBack() {
    setState(() => _activeFeature = null);
  }

  Widget _currentPage() {
    if (_activeFeature != null) {
      switch (_activeFeature) {
        case 'laporan': return const LaporanPageKS();
        case 'monitoring': return const BKPageKS();
        default: return DashboardPageKS(onFeatureTap: _openFeature, onLogout: _logout);
      }
    }
    switch (_shellTab) {
      case 1: return _buildActivityPage();
      case 2: return _buildProfilePage();
      default: return DashboardPageKS(onFeatureTap: _openFeature, onLogout: _logout);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 600) return _buildMobile();
        if (width < 1024) return _buildTablet();
        return _buildDesktop();
      },
    );
  }

  Widget _buildMobile() {
    if (_activeFeature != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
          title: Text(_activeFeature!),
          backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        ),
        body: _currentPage(),
      );
    }
    return Scaffold(
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _shellTab,
        onDestinationSelected: (i) { setState(() { _shellTab = i; _activeFeature = null; }); },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Aktivitas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _shellTab,
          onDestinationSelected: (i) { setState(() { _shellTab = i; _activeFeature = null; }); },
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.timeline), label: Text('Aktivitas')),
            NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _activeFeature != null
          ? Column(
              children: [
                Container(
                  height: 56, color: Colors.white,
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
                    const SizedBox(width: 8),
                    Text(_activeFeature!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(child: _currentPage()),
              ],
            )
          : _currentPage()),
      ],
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        NavigationRail(
          extended: true,
          selectedIndex: _shellTab,
          onDestinationSelected: (i) { setState(() { _shellTab = i; _activeFeature = null; }); },
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Text('Kamad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          trailing: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.timeline), label: Text('Aktivitas')),
            NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _activeFeature != null
          ? Column(
              children: [
                Container(
                  height: 56, color: Colors.white,
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
                    const SizedBox(width: 8),
                    Text(_activeFeature!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Divider(height: 1),
                Expanded(child: _currentPage()),
              ],
            )
          : _currentPage()),
      ],
    );
  }

  Widget _buildActivityPage() {
    return const Center(child: Text('Aktivitas', style: TextStyle(fontSize: 16, color: Colors.grey)));
  }

  Widget _buildProfilePage() {
    return const Center(child: Text('Profil', style: TextStyle(fontSize: 16, color: Colors.grey)));
  }
}
