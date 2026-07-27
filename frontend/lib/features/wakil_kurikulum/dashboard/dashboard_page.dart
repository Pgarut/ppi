import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final today = DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        title: Text('Wakil Kurikulum', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(20), children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Halo, Wakil Kurikulum', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(today, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6,
              children: [
                _StatCard(icon: Icons.calendar_month_outlined, label: 'Jadwal', value: '${_data?['jadwal'] ?? 0}', color: Colors.blue),
                _StatCard(icon: Icons.grading_outlined, label: 'Total Nilai', value: '${_data?['total_nilai'] ?? 0}', color: Colors.green),
                _StatCard(icon: Icons.pending_outlined, label: 'Nilai Draft', value: '${_data?['nilai_belum_divalidasi'] ?? 0}', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            Text('Menu Cepat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3,
              children: [
                _FeatureCard(icon: Icons.checklist_outlined, label: 'Absensi', onTap: () => widget.onFeatureTap('absensi')),
                _FeatureCard(icon: Icons.calendar_month_outlined, label: 'Penjadwalan', onTap: () => widget.onFeatureTap('penjadwalan')),
                _FeatureCard(icon: Icons.grading_outlined, label: 'Nilai', onTap: () => widget.onFeatureTap('nilai')),
                _FeatureCard(icon: Icons.trending_up_outlined, label: 'Kenaikan Kelas', onTap: () => widget.onFeatureTap('kenaikan-kelas')),
                _FeatureCard(icon: Icons.description_outlined, label: 'Laporan', onTap: () => widget.onFeatureTap('laporan')),
              ],
            ),
          ]),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: const Color(0xFF1B5E20), size: 28),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ]),
        ),
      ),
    );
  }
}
