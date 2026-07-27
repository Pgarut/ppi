import 'package:flutter/material.dart';
import '../services/guru_service.dart';

class DashboardPageGuru extends StatefulWidget {
  const DashboardPageGuru({super.key});

  @override
  State<DashboardPageGuru> createState() => _DashboardPageGuruState();
}

class _DashboardPageGuruState extends State<DashboardPageGuru> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await GuruService.getDashboard();
      setState(() => _stats = data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    _stats ??= {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard Guru', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 16,
          children: [
            _StatCard('Jadwal Hari Ini', _stats!['jadwal_hari_ini']?.toString() ?? '0', Icons.calendar_today, Colors.blue),
            _StatCard('Total Absensi', _stats!['total_absensi']?.toString() ?? '0', Icons.checklist, Colors.green),
            _StatCard('Total Nilai', _stats!['total_nilai']?.toString() ?? '0', Icons.grading, Colors.orange),
            _StatCard('Pengaduan Aktif', _stats!['pengaduan_aktif']?.toString() ?? '0', Icons.warning_amber, Colors.red),
          ],
        ),
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
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
