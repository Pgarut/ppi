import 'package:flutter/material.dart';
import '../services/guru_bk_service.dart';

class DashboardPageBK extends StatefulWidget {
  const DashboardPageBK({super.key});

  @override
  State<DashboardPageBK> createState() => _DashboardPageBKState();
}

class _DashboardPageBKState extends State<DashboardPageBK> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _stats = await GuruBKService.getStatistik();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final perKategori = (_stats?['per_kategori'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard BK', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 16,
          children: [
            _Card('Total Pengaduan', '${_stats?['total_pengaduan'] ?? 0}', Icons.list_alt, Colors.blue),
            _Card('Aktif Diproses', '${_stats?['aktif_diproses'] ?? 0}', Icons.engineering, Colors.orange),
            _Card('Selesai', '${_stats?['selesai'] ?? 0}', Icons.check_circle, Colors.green),
            _Card('Total Konseling', '${_stats?['total_konseling'] ?? 0}', Icons.support_agent, Colors.indigo),
          ],
        ),
        const SizedBox(height: 24),
        Text('Per Kategori', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...perKategori.map((k) => ListTile(
          leading: Icon(k['kategori'] == 'kasus' ? Icons.gavel : Icons.warning, color: Colors.red),
          title: Text(k['kategori']?.toString() ?? ''),
          trailing: Text('${k['jumlah']}', style: Theme.of(context).textTheme.titleMedium),
        )),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _Card(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
