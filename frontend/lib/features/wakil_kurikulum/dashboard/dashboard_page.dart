import 'package:flutter/material.dart';
import '../services/wakil_kurikulum_service.dart';

class DashboardPageWK extends StatefulWidget {
  const DashboardPageWK({super.key});

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ringkasan Akademik', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6,
                children: [
                  _StatCard(Icons.calendar_month_outlined, 'Jadwal', '${_data?['jadwal'] ?? 0}', Colors.blue),
                  _StatCard(Icons.grading_outlined, 'Total Nilai', '${_data?['total_nilai'] ?? 0}', Colors.green),
                  _StatCard(Icons.pending_outlined, 'Nilai Draft', '${_data?['nilai_belum_divalidasi'] ?? 0}', Colors.orange),
                ],
              ),
            ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatCard(this.icon, this.label, this.value, this.color);

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
