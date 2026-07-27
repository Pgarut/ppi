import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services/kepala_sekolah_service.dart';

class DashboardPageKS extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  final VoidCallback? onLogout;

  const DashboardPageKS({super.key, this.onFeatureTap, this.onLogout});

  @override
  State<DashboardPageKS> createState() => _DashboardPageKSState();
}

class _DashboardPageKSState extends State<DashboardPageKS> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _data = await KepalaSekolahService.getDashboard();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final stats = _data?['statistik'] as Map<String, dynamic>? ?? {};
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Header(onLogout: widget.onLogout),
        const SizedBox(height: 24),
        Text('Ringkasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildStatGrid(theme, stats),
        const SizedBox(height: 24),
        Text('Menu Utama', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildFeatureGrid(),
      ],
    );
  }

  Widget _buildStatGrid(ThemeData theme, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 900 ? 4 : (w > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard('Siswa Aktif', '${stats['total_siswa'] ?? 0}', Icons.people_outline, const Color(0xFF1B5E20)),
            _StatCard('Guru', '${stats['total_guru'] ?? 0}', Icons.school_outlined, const Color(0xFF2E7D32)),
            _StatCard('Kelas', '${stats['total_kelas'] ?? 0}', Icons.meeting_room_outlined, const Color(0xFF43A047)),
            _StatCard('Mapel', '${stats['total_mapel'] ?? 0}', Icons.book_outlined, const Color(0xFF66BB6A)),
          ],
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    const features = [
      _FeatureData('Statistik', 'statistik', Icons.bar_chart_outlined, 'Ringkasan statistik sekolah', Color(0xFF1B5E20)),
      _FeatureData('Laporan', 'laporan', Icons.description_outlined, 'Generate & unduh laporan', Color(0xFF2E7D32)),
      _FeatureData('Monitoring', 'monitoring', Icons.trending_up_outlined, 'Pantau aktivitas sekolah', Color(0xFF43A047)),
      _FeatureData('Grafik Sekolah', 'grafik-sekolah', Icons.pie_chart, 'Visualisasi data sekolah', Color(0xFFFDD835)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 1100 ? 4 : (w > 700 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: features.map((f) {
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (f.key == 'statistik' || f.key == 'grafik-sekolah') {
                    _showComingSoon(f.label);
                  } else {
                    widget.onFeatureTap?.call(f.key);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(f.icon, color: f.color, size: 28),
                      ),
                      const Spacer(),
                      Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(f.desc, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showComingSoon(String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('Fitur $label akan segera tersedia'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
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
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final today = DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1B5E20),
          child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat Datang, $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(roleDisplay, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(today, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: const Color(0xFF1B5E20),
          onPressed: () {},
        ),
        if (onLogout != null)
          IconButton(icon: const Icon(Icons.logout), color: Colors.grey, onPressed: onLogout),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

class _FeatureData {
  final String label, key, desc;
  final IconData icon;
  final Color color;
  const _FeatureData(this.label, this.key, this.icon, this.desc, this.color);
}
