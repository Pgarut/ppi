import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
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

  const DashboardTemplate({
    super.key,
    this.loading = false,
    this.stats = const [],
    this.features = const [],
    this.onFeatureTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const _Header(),
        const SizedBox(height: 28),
        _buildSectionTitle('Ringkasan'),
        const SizedBox(height: 16),
        _StatGrid(stats: stats),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionTitle('Menu Utama'),
          const SizedBox(height: 16),
          _FeatureGrid(features: features, onFeatureTap: onFeatureTap),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.grey800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.displayName ?? 'Pengguna';
    final roleDisplay = UserModel.roleDisplayName(user?.role ?? '');

    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 10) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
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
        final ratio = w > 600 ? 1.5 : 1.1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: ratio,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: item.color,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (_, i) => _FeatureCard(item: features[i], onTap: onFeatureTap),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureItem item;
  final void Function(String feature)? onTap;
  const _FeatureCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = item.isSecondary ? AppTheme.secondary : AppTheme.primary;
    final bgColor = item.isSecondary ? AppTheme.secondaryLight : AppTheme.primaryLight;
    final iconColor = item.isSecondary ? AppTheme.orange : AppTheme.primaryDark;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap != null ? () => onTap!(item.key) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.grey200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      primaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, size: 24, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.grey700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.grey400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
