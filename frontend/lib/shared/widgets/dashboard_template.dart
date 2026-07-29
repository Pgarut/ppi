import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';

class StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const StatItem(this.icon, this.label, this.value, this.color);
}

class FeatureItem {
  final String label, key, desc;
  final IconData icon;
  final bool isSecondary;
  const FeatureItem(this.label, this.key, this.icon, this.desc, {this.isSecondary = false});
}

class DashboardTemplate extends StatelessWidget {
  final bool loading;
  final List<StatItem> stats;
  final List<FeatureItem> features;
  final void Function(String feature)? onFeatureTap;
  final VoidCallback? onLogout;

  const DashboardTemplate({
    super.key,
    this.loading = false,
    this.stats = const [],
    this.features = const [],
    this.onFeatureTap,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Header(onLogout: onLogout),
        const SizedBox(height: 24),
        Text('Ringkasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _StatGrid(stats: stats),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Menu Utama', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _FeatureGrid(features: features, onFeatureTap: onFeatureTap),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onLogout;
  const _Header({this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.username ?? 'Pengguna';
    final roleDisplay = UserModel.roleDisplayName(user?.role ?? '');

    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(roleDisplay, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: const Color(0xFF2E7D32),
          onPressed: () {},
        ),
        if (onLogout != null)
          IconButton(icon: const Icon(Icons.logout), color: Colors.grey, onPressed: onLogout),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<StatItem> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 900 ? 4 : (w > 600 ? 3 : 2);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          itemBuilder: (_, i) => _StatCard(item: stats[i]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: item.color)),
            Text(item.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        )),
      ]),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<FeatureItem> features;
  final void Function(String feature)? onFeatureTap;
  const _FeatureGrid({required this.features, this.onFeatureTap});

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (_, i) => _FeatureCard(item: features[i], onTap: onFeatureTap),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureItem item;
  final void Function(String feature)? onTap;
  const _FeatureCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap != null ? () => onTap!(item.key) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.isSecondary
                        ? [const Color(0xFFFFF8E1), const Color(0xFFFFE082)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (item.isSecondary ? const Color(0xFFF9A825) : const Color(0xFF2E7D32))
                          .withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(item.icon, size: 22,
                    color: item.isSecondary ? const Color(0xFFE65100) : const Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(item.label,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}