import 'package:flutter/material.dart';
import '../services/kepala_sekolah_service.dart';

class DashboardPageKS extends StatefulWidget {
  const DashboardPageKS({super.key});

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
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final stats = _data?['statistik'] as Map<String, dynamic>? ?? {};
    final jadwalPerHari = _data?['jadwal_per_hari'] as List<dynamic>? ?? [];
    final absensiRekap = _data?['absensi_rekap'] as List<dynamic>? ?? [];
    final nilaiDist = _data?['nilai_distribusi'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dashboard Kepala Sekolah', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16, runSpacing: 16,
          children: [
            _StatCard('Siswa Aktif', '${stats['total_siswa'] ?? 0}', Icons.people, Colors.blue),
            _StatCard('Guru', '${stats['total_guru'] ?? 0}', Icons.school, Colors.green),
            _StatCard('Kelas', '${stats['total_kelas'] ?? 0}', Icons.meeting_room, Colors.orange),
            _StatCard('Mapel', '${stats['total_mapel'] ?? 0}', Icons.book, Colors.purple),
          ],
        ),
        const SizedBox(height: 24),
        Text('Jadwal per Hari', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...jadwalPerHari.map((j) => ListTile(
          leading: Icon(_hariIcon(j['hari']?.toString() ?? ''), color: Colors.teal),
          title: Text('Hari ${j['hari'] ?? ''}'),
          trailing: Text('${j['jumlah'] ?? 0} pelajaran'),
        )),
        const SizedBox(height: 16),
        Text('Rekap Absensi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...absensiRekap.map((a) => ListTile(
          leading: Icon(_absIcon(a['status']?.toString() ?? ''), color: _absColor(a['status']?.toString() ?? '')),
          title: Text(a['status']?.toString() ?? ''),
          trailing: Text('${a['jumlah'] ?? 0}'),
        )),
        const SizedBox(height: 16),
        Text('Distribusi Nilai', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...nilaiDist.map((n) => ListTile(
          title: Text('${n['jenis'] ?? ''}'),
          subtitle: Text('Rata-rata: ${n['rata_rata'] ?? '-'}'),
          trailing: Text('${n['jumlah'] ?? 0}'),
        )),
      ],
    );
  }

  IconData _hariIcon(String h) {
    switch (h.toLowerCase()) {
      case 'senin': return Icons.looks_one;
      case 'selasa': return Icons.looks_two;
      case 'rabu': return Icons.looks_3;
      case 'kamis': return Icons.looks_4;
      case 'jumat': return Icons.looks_5;
      case 'sabtu': return Icons.looks_6;
      default: return Icons.calendar_today;
    }
  }

  IconData _absIcon(String s) {
    switch (s) {
      case 'hadir': return Icons.check_circle;
      case 'izin': return Icons.info;
      case 'sakit': return Icons.local_hospital;
      case 'alpa': return Icons.cancel;
      default: return Icons.help;
    }
  }

  Color _absColor(String s) {
    switch (s) {
      case 'hadir': return Colors.green;
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
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
