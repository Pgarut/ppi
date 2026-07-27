import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class AcademicShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final String title;
  final List<NavItem> menuItems;

  const AcademicShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
    required this.title,
    required this.menuItems,
  });

  @override
  State<AcademicShell> createState() => _AcademicShellState();
}

class _AcademicShellState extends State<AcademicShell> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        if (isMobile) return _buildMobileLayout();
        return _buildDesktopLayout();
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Material(
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopbar(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: _buildMobileAppBar(),
      drawer: _buildMobileDrawer(),
      body: widget.child,
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
            color: Color(0xFF1B5E20),
            border: Border(right: BorderSide(color: Color(0xFF2E7D32))),
          ),
        child: Column(children: [
          _buildSidebarHeader(),
          const Divider(color: Color(0xFF334155), height: 1),
          Expanded(child: _buildNavItems()),
          _buildLogout(),
        ]),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 0),
      child: Row(
        mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.school, color: Colors.white, size: 22),
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 10),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.menuItems.length,
      itemBuilder: (_, i) {
        final item = widget.menuItems[i];
        final isActive = widget.currentIndex == i;
        return Tooltip(
          message: _isExpanded ? '' : item.label,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFDD835).withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onNavigate(i),
              child: Container(
                height: 44,
                padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 12 : 0),
                child: Row(
                  mainAxisAlignment: _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: isActive ? const Color(0xFFFDD835) : Colors.grey[400], size: 20),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Text(item.label, style: TextStyle(color: isActive ? const Color(0xFFFDD835) : Colors.grey[400], fontSize: 13)),
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
                Icon(Icons.logout, size: 20, color: Colors.grey[400]),
                if (_isExpanded) ...[
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text(widget.menuItems[widget.currentIndex].label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_outline, size: 16, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(widget.title, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
          ]),
        ),
      ]),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      title: Text(widget.menuItems[widget.currentIndex].label),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Icon(Icons.school, color: Color(0xFFFDD835), size: 40),
            const SizedBox(height: 8),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),
        ...widget.menuItems.asMap().entries.map((e) => ListTile(
          leading: Icon(e.value.icon),
          title: Text(e.value.label),
          selected: widget.currentIndex == e.key,
          onTap: () { widget.onNavigate(e.key); Navigator.pop(context); },
        )),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
          },
        ),
      ]),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  NavItem(this.icon, this.label);
}
