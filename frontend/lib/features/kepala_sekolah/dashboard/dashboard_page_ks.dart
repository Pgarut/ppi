import 'package:flutter/material.dart';
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
    setState(() => _loading = false);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 10) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    return 'Selamat Sore';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final stats = _data?['statistik'] as Map<String, dynamic>? ?? {};
    final jadwalPerHari = _data?['jadwal_per_hari'] as List<dynamic>? ?? [];
    final absensiRekap = _data?['absensi_rekap'] as List<dynamic>? ?? [];

    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _buildHeader(theme),
        const SizedBox(height: 24),
        _buildStatGrid(theme, stats),
        const SizedBox(height: 24),
        Text('Akses Cepat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildFeatureGrid(isWide),
        if (jadwalPerHari.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Jadwal per Hari', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildJadwalCard(jadwalPerHari),
        ],
        if (absensiRekap.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Rekap Absensi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildAbsensiCard(absensiRekap),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final dateStr = '${days[now.weekday]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Kepala Madrasah (Kamad)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 2),
              Text(dateStr, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.notifications_outlined, color: Color(0xFF1B5E20), size: 24),
        ),
      ],
    );
  }

  Widget _buildStatGrid(ThemeData theme, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard('Siswa Aktif', '${stats['total_siswa'] ?? 0}', Icons.people_outline, const Color(0xFF1B5E20), Colors.green[50]!),
            _StatCard('Guru', '${stats['total_guru'] ?? 0}', Icons.school_outlined, const Color(0xFF2E7D32), Colors.green[50]!),
            _StatCard('Kelas', '${stats['total_kelas'] ?? 0}', Icons.meeting_room_outlined, const Color(0xFF43A047), Colors.green[50]!),
            _StatCard('Mapel', '${stats['total_mapel'] ?? 0}', Icons.book_outlined, const Color(0xFF66BB6A), Colors.green[50]!),
          ],
        );
      },
    );
  }

  Widget _buildFeatureGrid(bool isWide) {
    const features = [
      ('Jadwal', 'jadwal', Icons.calendar_month_outlined, 'Lihat jadwal', Color(0xFF1B5E20)),
      ('Absensi', 'absensi', Icons.checklist_outlined, 'Rekap kehadiran', Color(0xFF2E7D32)),
      ('Nilai', 'nilai', Icons.grade_outlined, 'Distribusi nilai', Color(0xFF43A047)),
      ('Rapor', 'rapor', Icons.assignment_outlined, 'Status rapor', Color(0xFF66BB6A)),
      ('BK', 'bk', Icons.psychology_outlined, 'Monitoring BK', Color(0xFFFDD835)),
      ('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan', Color(0xFFFFCA28)),
    ];

    return GridView.count(
      crossAxisCount: isWide ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: features.map((f) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => widget.onFeatureTap?.call(f.$2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: f.$5.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.$3, color: f.$5, size: 28),
                  ),
                  const Spacer(),
                  Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(f.$4, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJadwalCard(List<dynamic> jadwal) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: jadwal.map((j) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Text(j['hari']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1B5E20))),
              ),
              const Spacer(),
              Text('${j['jumlah'] ?? 0} pelajaran', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildAbsensiCard(List<dynamic> absensi) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: absensi.map((a) {
            final status = a['status']?.toString() ?? '';
            final color = switch (status) { 'hadir' => Colors.green, 'sakit' => Colors.blue, 'izin' => Colors.orange, _ => Colors.red };
            final jumlah = a['jumlah'] ?? 0;
            return Expanded(
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.circle, color: color, size: 12),
                ),
                const SizedBox(height: 4),
                Text('$jumlah', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(status, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, bgColor;

  const _StatCard(this.title, this.value, this.icon, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
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
