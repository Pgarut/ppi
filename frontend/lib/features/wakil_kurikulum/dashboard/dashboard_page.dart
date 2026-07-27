import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../services/wakil_kurikulum_service.dart';

class DashboardPageWK extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  final VoidCallback onLogout;
  const DashboardPageWK({super.key, required this.onFeatureTap, required this.onLogout});

  @override
  State<DashboardPageWK> createState() => _DashboardPageWKState();
}

class _DashboardPageWKState extends State<DashboardPageWK> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await WakilKurikulumService.getDashboard(); }
    catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _Header(onLogout: widget.onLogout),
        const SizedBox(height: 24),
        Text('Ringkasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildStatGrid(),
        const SizedBox(height: 24),
        Text('Menu Utama', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildFeatureGrid(),
      ],
    );
  }

  Widget _buildStatGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 900 ? 4 : (w > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _StatCard(icon: Icons.calendar_month_outlined, label: 'Jadwal', value: '${_data?['jadwal'] ?? 0}', color: Colors.blue),
            _StatCard(icon: Icons.grading_outlined, label: 'Total Nilai', value: '${_data?['total_nilai'] ?? 0}', color: Colors.green),
            _StatCard(icon: Icons.pending_outlined, label: 'Nilai Draft', value: '${_data?['nilai_belum_divalidasi'] ?? 0}', color: Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    const features = [
      _FeatureData('Absensi', 'absensi', Icons.checklist_outlined, 'Rekap kehadiran siswa & guru', Color(0xFF1B5E20)),
      _FeatureData('Penjadwalan', 'penjadwalan', Icons.calendar_month_outlined, 'Atur jadwal pelajaran', Color(0xFF2E7D32)),
      _FeatureData('Nilai', 'nilai', Icons.grading_outlined, 'Validasi & kelola nilai', Color(0xFF43A047)),
      _FeatureData('Kenaikan Kelas', 'kenaikan-kelas', Icons.trending_up_outlined, 'Proses kenaikan kelas', Color(0xFF66BB6A)),
      _FeatureData('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan akademik', Color(0xFFFDD835)),
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
                onTap: () => widget.onFeatureTap(f.key),
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
}

class _Header extends StatelessWidget {
  final VoidCallback onLogout;
  const _Header({required this.onLogout});

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
        IconButton(icon: const Icon(Icons.logout), color: Colors.grey, onPressed: onLogout),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
      ]),
    );
  }
}

class _FeatureData {
  final String label, key, desc;
  final IconData icon;
  final Color color;
  const _FeatureData(this.label, this.key, this.icon, this.desc, this.color);
}
