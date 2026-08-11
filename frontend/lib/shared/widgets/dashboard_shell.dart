import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../widgets/pages/profil_page.dart';
import '../widgets/pages/bantuan_page.dart';
import '../widgets/pages/tentang_page.dart';
import '../widgets/pages/scan_absen_page.dart';
import '../widgets/app_utils.dart';

class DashboardShell extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext, void Function(String), VoidCallback) dashboardBuilder;
  final Map<String, WidgetBuilder> features;
  final WidgetBuilder? profilePage;
  final WidgetBuilder? settingsPage;
  final WidgetBuilder? scanPage;
  final Widget Function(BuildContext, VoidCallback)? scanPageBuilder;
  final bool showScanTab;

  const DashboardShell({
    super.key,
    required this.title,
    required this.dashboardBuilder,
    this.features = const {},
    this.profilePage,
    this.settingsPage,
    this.scanPage,
    this.scanPageBuilder,
    this.showScanTab = false,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _shellTab = 0;
  String? _activeFeature;

  static const Map<String, String> _featureLabels = {
    'jadwal': 'Jadwal Pelajaran',
    'absensi': 'Riwayat Kehadiran',
    'nilai': 'Nilai Akademik',
    'materi': 'Materi Pembelajaran',
    'dauroh': 'Program Dauroh',
    'santri': 'Data Santri',
    'guru': 'Data Guru',
    'kelas': 'Data Kelas',
    'mata_pelajaran': 'Mata Pelajaran',
    'semester': 'Semester',
    'program': 'Program',
    'pengaturan': 'Pengaturan',
  };

  void _openFeature(String feature) {
    setState(() => _activeFeature = feature);
  }

  void _goBack() {
    setState(() => _activeFeature = null);
  }

  Future<void> _logout() async {
    final confirm = await AppUtils.confirm(
      context,
      title: 'Yakin ingin logout?',
      message: 'Anda akan keluar dari sistem. Data yang belum disimpan akan hilang.',
      confirmText: 'Logout',
      confirmColor: AppTheme.error,
    );
    if (!confirm) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
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
    // Scan tab (index 2 jika showScanTab aktif)
    if (widget.showScanTab && _shellTab == 2) {
      if (widget.scanPageBuilder != null) {
        return widget.scanPageBuilder!(context, () {
          setState(() => _shellTab = 0);
        });
      }
      return widget.scanPage?.call(context) ?? ScanAbsenPage(onBack: () {
        setState(() => _shellTab = 0);
      });
    }

    // Profil tab: index 3 jika showScanTab aktif, index 2 jika tidak
    final profileIndex = widget.showScanTab ? 3 : 2;
    if (_shellTab == profileIndex) {
      return widget.profilePage?.call(context) ?? ProfilPage(onLogout: _logout);
    }

    return widget.dashboardBuilder(context, _openFeature, _logout);
  }

  Widget _placeholderPage(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined, size: 48, color: AppTheme.grey300),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: AppTheme.grey500)),
        ],
      ),
    );
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

  // ═══════════════════════════════════════════════════════════
  //  MOBILE - Bottom Navigation + Drawer
  // ═══════════════════════════════════════════════════════════
  Widget _buildMobile() {
    if (_activeFeature != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _goBack,
          ),
          title: Text(_featureLabels[_activeFeature!] ?? _activeFeature!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
        ),
        drawer: _buildDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey('feature$_activeFeature'), child: _currentPage()),
        ),
      );
    }

    // Jika showScanTab dan tab scan aktif, gunakan scaffold berbeda
    if (widget.showScanTab && _shellTab == 2) {
      return _currentPage();
    }

    return Scaffold(
      drawer: _buildDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _shellTab,
          onDestinationSelected: (i) {
            setState(() { _shellTab = i; _activeFeature = null; });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard, size: 22),
              label: 'Beranda',
            ),
            const NavigationDestination(
              icon: Icon(Icons.timeline_outlined, size: 22),
              selectedIcon: Icon(Icons.timeline, size: 22),
              label: 'Aktivitas',
            ),
            if (widget.showScanTab)
              const NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined, size: 22),
                selectedIcon: Icon(Icons.qr_code_scanner, size: 22),
                label: 'Scan',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline, size: 22),
              selectedIcon: Icon(Icons.person, size: 22),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TABLET - NavigationRail
  // ═══════════════════════════════════════════════════════════
  Widget _buildTablet() {
    return Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: AppTheme.grey200)),
          ),
          child: NavigationRail(
            selectedIndex: _shellTab,
            onDestinationSelected: (i) {
              setState(() { _shellTab = i; _activeFeature = null; });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    icon: const Icon(Icons.logout_outlined, color: AppTheme.error),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Beranda'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.timeline_outlined),
                selectedIcon: Icon(Icons.timeline),
                label: Text('Aktivitas'),
              ),
              if (widget.showScanTab)
                const NavigationRailDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.qr_code_scanner),
                  label: Text('Scan'),
                ),
              const NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profil'),
              ),
            ],
          ),
        ),
        Expanded(child: _activeFeature != null
            ? _buildFeatureWithBack()
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
              )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DESKTOP - Dark Sidebar
  // ═══════════════════════════════════════════════════════════
  Widget _buildDesktop() {
    return Row(
      children: [
        _buildDarkSidebar(),
        Expanded(child: _activeFeature != null
            ? _buildFeatureWithBack()
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey('tab$_shellTab'), child: _currentPage()),
              )),
      ],
    );
  }

  Widget _buildDarkSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: AppTheme.sidebarGradient,
        border: Border(right: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: Column(
        children: [
          // ── Logo + Title ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem Informasi',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Divider ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),

          const SizedBox(height: 16),

          // ── User Info ──
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              final displayName = auth.user?.displayName ?? 'User';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.user?.role ?? '',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Navigation Items ──
          _sidebarItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: _shellTab == 0 && _activeFeature == null,
            onTap: () => setState(() { _shellTab = 0; _activeFeature = null; }),
          ),
          _sidebarItem(
            icon: Icons.timeline_outlined,
            selectedIcon: Icons.timeline,
            label: 'Aktivitas',
            isSelected: _shellTab == 1 && _activeFeature == null,
            onTap: () => setState(() { _shellTab = 1; _activeFeature = null; }),
          ),
          if (widget.showScanTab)
            _sidebarItem(
              icon: Icons.qr_code_scanner_outlined,
              selectedIcon: Icons.qr_code_scanner,
              label: 'Scan Absen',
              isSelected: _shellTab == 2 && _activeFeature == null,
              onTap: () => setState(() { _shellTab = 2; _activeFeature = null; }),
            ),
          _sidebarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profil',
            isSelected: _shellTab == (widget.showScanTab ? 3 : 2) && _activeFeature == null,
            onTap: () => setState(() { _shellTab = widget.showScanTab ? 3 : 2; _activeFeature = null; }),
          ),

          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 8),

          _sidebarItem(
            icon: Icons.help_outline,
            label: 'Bantuan',
            onTap: () => _openFeature('__bantuan__'),
          ),
          _sidebarItem(
            icon: Icons.info_outline,
            label: 'Tentang',
            onTap: () => _openFeature('__tentang__'),
          ),

          const Spacer(),

          // ── Logout ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_outlined, color: AppTheme.error, size: 18),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? (selectedIcon ?? icon) : icon,
                  size: 20,
                  color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FEATURE WITH BACK
  // ═══════════════════════════════════════════════════════════
  Widget _buildFeatureWithBack() {
    return Material(
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.grey200)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: _goBack,
                ),
                const SizedBox(width: 4),
                Text(
                  _featureLabels[_activeFeature!] ?? _activeFeature!,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.grey800),
                ),
              ],
            ),
          ),
          Expanded(child: _currentPage()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DRAWER (Mobile)
  // ═══════════════════════════════════════════════════════════
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppTheme.sidebarGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      final displayName = auth.user?.displayName ?? 'User';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                            child: Text(
                              displayName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  auth.user?.role ?? '',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Menu Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _drawerItem(
                    icon: Icons.person_outline,
                    label: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() { _shellTab = widget.showScanTab ? 3 : 2; _activeFeature = null; });
                    },
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Pengaturan',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.settingsPage != null) {
                        _openFeature('__settings__');
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Halaman Pengaturan sedang dalam pengembangan')),
                        );
                      }
                    },
                  ),
                  _drawerItem(
                    icon: Icons.help_outline,
                    label: 'Bantuan',
                    onTap: () {
                      Navigator.pop(context);
                      _openFeature('__bantuan__');
                    },
                  ),
                  _drawerItem(
                    icon: Icons.info_outline,
                    label: 'Tentang',
                    onTap: () {
                      Navigator.pop(context);
                      _openFeature('__tentang__');
                    },
                  ),
                ],
              ),
            ),

            // ── Logout ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ListTile(
                leading: const Icon(Icons.logout_outlined, color: AppTheme.error),
                title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.redLight,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.grey600, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
