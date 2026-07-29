import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../widgets/pages/profil_page.dart';
import '../widgets/pages/bantuan_page.dart';
import '../widgets/pages/tentang_page.dart';

class DashboardShell extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext, void Function(String), VoidCallback) dashboardBuilder;
  final Map<String, WidgetBuilder> features;
  final WidgetBuilder? profilePage;
  final WidgetBuilder? settingsPage;

  const DashboardShell({
    super.key,
    required this.title,
    required this.dashboardBuilder,
    this.features = const {},
    this.profilePage,
    this.settingsPage,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _shellTab = 0;
  String? _activeFeature;

  void _openFeature(String feature) {
    setState(() => _activeFeature = feature);
  }

  void _goBack() {
    setState(() => _activeFeature = null);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yakin ingin logout?'),
        content: const Text('Anda akan keluar dari sistem. Data yang belum disimpan akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _currentPage() {
    if (_activeFeature != null) {
      switch (_activeFeature) {
        case '__settings__':
          return widget.settingsPage?.call(context) ?? _placeholderPage('Pengaturan');
        case '__bantuan__':
          return const BantuanPage();
        case '__tentang__':
          return const TentangPage();
        default:
          final builder = widget.features[_activeFeature!];
          if (builder != null) return builder(context);
      }
    }
    switch (_shellTab) {
      case 2:
        return widget.profilePage?.call(context) ?? ProfilPage(onLogout: _logout);
      default:
        return widget.dashboardBuilder(context, _openFeature, _logout);
    }
  }

  Widget _placeholderPage(String label) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)));
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
        drawer: _buildDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey('feature$_activeFeature'), child: _currentPage()),
        ),
      );
    }
    return Scaffold(
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF2E7D32),
            onPrimary: Colors.white,
          ),
        ),
        child: NavigationBar(
          selectedIndex: _shellTab,
          onDestinationSelected: (i) { setState(() { _shellTab = i; _activeFeature = null; }); },
          indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.timeline), label: 'Aktivitas'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
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
          selectedIconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
          selectedLabelTextStyle: const TextStyle(color: Color(0xFF2E7D32)),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.timeline), label: Text('Aktivitas')),
            NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _activeFeature != null
          ? _buildFeatureWithBack()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
            )),
      ],
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        NavigationRail(
          extended: true,
          labelType: NavigationRailLabelType.none,
          selectedIndex: _shellTab,
          onDestinationSelected: (i) { setState(() { _shellTab = i; _activeFeature = null; }); },
          selectedIconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
          selectedLabelTextStyle: const TextStyle(color: Color(0xFF2E7D32)),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          ? _buildFeatureWithBack()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
            )),
      ],
    );
  }

  Widget _buildFeatureWithBack() {
    return Column(
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      final username = auth.user?.username ?? 'User';
                      final role = auth.user?.role ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(role, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.person_outline, 'Profil', () {
                    Navigator.pop(context);
                    _shellTab = 2;
                    _activeFeature = null;
                    setState(() {});
                  }),
                  _drawerItem(Icons.settings_outlined, 'Pengaturan', () {
                    Navigator.pop(context);
                    if (widget.settingsPage != null) {
                      _openFeature('__settings__');
                      setState(() {});
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Halaman Pengaturan sedang dalam pengembangan')),
                      );
                    }
                  }),
                  _drawerItem(Icons.help_outline, 'Bantuan', () {
                    Navigator.pop(context);
                    _openFeature('__bantuan__');
                  }),
                  _drawerItem(Icons.info_outline, 'Tentang', () {
                    Navigator.pop(context);
                    _openFeature('__tentang__');
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  }