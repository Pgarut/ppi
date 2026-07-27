import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await AdminService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = _data!['ringkasan'] as Map<String, dynamic>;
    final d = _data!['detail'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Sistem', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _buildStatGrid(r),
          const SizedBox(height: 32),
          Text('Statistik Detail', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildDetailGrid(d),
        ],
      ),
    );
  }

  Widget _buildStatGrid(Map<String, dynamic> r) {
    final stats = [
      _SC(Icons.people_outline, 'Guru', '${r['guru'] ?? 0}', const Color(0xFF1A73E8)),
      _SC(Icons.person_outline, 'Siswa', '${r['siswa'] ?? 0}', const Color(0xFF34A853)),
      _SC(Icons.meeting_room_outlined, 'Kelas', '${r['kelas'] ?? 0}', const Color(0xFFFBBC04)),
      _SC(Icons.checklist_outlined, 'Absensi Hari Ini', '${r['absensi_hari_ini'] ?? 0}', const Color(0xFFEA4335)),
      _SC(Icons.grading_outlined, 'Nilai', '${r['nilai'] ?? 0}', const Color(0xFF9C27B0)),
      _SC(Icons.calendar_month_outlined, 'Jadwal', '${r['jadwal'] ?? 0}', const Color(0xFFFF5722)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16, mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: stats.map((s) => _StatCard(icon: s.icon, label: s.label, value: s.value, color: s.color)).toList(),
        );
      },
    );
  }

  Widget _buildDetailGrid(Map<String, dynamic> d) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 2 : 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16, mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _DetailCard(title: 'Statistik Guru', data: d['guru'] as Map<String, dynamic>? ?? {}),
            _DetailCard(title: 'Statistik Siswa', data: d['siswa'] as Map<String, dynamic>? ?? {}),
            _DetailCard(title: 'Statistik Absensi (Hari Ini)', data: d['absensi'] as Map<String, dynamic>? ?? {}),
            _DetailCard(title: 'Statistik Nilai', data: d['nilai'] as Map<String, dynamic>? ?? {}),
          ],
        );
      },
    );
  }
}

class _SC {
  final IconData icon; final String label; final String value; final Color color;
  _SC(this.icon, this.label, this.value, this.color);
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
      ]),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title; final Map<String, dynamic> data;
  const _DetailCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...data.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text('${e.key}: ${e.value}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        ]))),
        if (data.isEmpty) Text('Belum ada data', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
    );
  }
}
