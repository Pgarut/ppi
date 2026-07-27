import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const AdminShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _isExpanded = false;

  final _menuItems = [
    _MenuItem(Icons.dashboard_outlined, 'Dashboard', 0),
    _MenuItem(Icons.storage_outlined, 'Master Data', 1),
    _MenuItem(Icons.calendar_today_outlined, 'Absensi', 2),
    _MenuItem(Icons.grading_outlined, 'Nilai', 3),
    _MenuItem(Icons.description_outlined, 'Rapor', 4),
    _MenuItem(Icons.settings_outlined, 'Pengaturan', 5),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isExpanded ? 220 : 64,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(
            right: BorderSide(color: Color(0xFF334155)),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Color(0xFF334155), height: 1),
            Expanded(child: _buildNavItems()),
            _buildLogout(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 0),
      child: Row(
        mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 12),
            const Text('PPI Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isActive = widget.currentIndex == index;

        return Tooltip(
          message: _isExpanded ? '' : item.label,
          preferBelow: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onNavigate(index),
              child: Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
                child: Row(
                  mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: isActive ? Colors.white : Colors.grey[400], size: 20),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Text(item.label, style: TextStyle(color: isActive ? Colors.white : Colors.grey[400], fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogout() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Tooltip(
        message: _isExpanded ? '' : 'Logout',
        preferBelow: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
          },
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
            child: Row(
              mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.grey[400], size: 20),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  _MenuItem(this.icon, this.label, this.index);
}
