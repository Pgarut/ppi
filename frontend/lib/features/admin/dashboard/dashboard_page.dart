import 'package:flutter/material.dart';
import '../services/admin_service.dart';

const Color _green = Color(0xFF2E7D32);
const Color _greenLight = Color(0xFF4CAF50);
const Color _greenBg = Color(0xFFE8F5E9);
const Color _yellow = Color(0xFFF9A825);

const Color _yellowBg = Color(0xFFFFFBF0);
const Color _white = Color(0xFFFFFFFF);
const Color _bg = Color(0xFFF8FAF5);

class DashboardPage extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  final VoidCallback? onLogout;
  const DashboardPage({super.key, this.onFeatureTap, this.onLogout});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _load();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 10) _greeting = 'Selamat Pagi';
      else if (hour < 15) _greeting = 'Selamat Siang';
      else if (hour < 18) _greeting = 'Selamat Sore';
      else _greeting = 'Selamat Malam';
    });
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
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = _data!['ringkasan'] as Map<String, dynamic>;
    final d = _data!['detail'] as Map<String, dynamic>;

    return RefreshIndicator(
      color: _green,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(r),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ringkasan Data'),
                  const SizedBox(height: 16),
                  _buildStatGrid(r),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Statistik Detail'),
                  const SizedBox(height: 16),
                  _buildDetailGrid(d),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Menu Fitur'),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> r) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenLight, Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Dashboard Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _load,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildHeaderChip(Icons.people_outline, '${r['guru'] ?? 0} Asatidz'),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.person_outline, '${r['siswa'] ?? 0} Santri'),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.meeting_room_outlined, '${r['kelas'] ?? 0} Kelas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(Map<String, dynamic> r) {
    final stats = [
      _StatItem(Icons.people_outline, 'Asatidz', '${r['guru'] ?? 0}', _green, _greenBg),
      _StatItem(Icons.person_outline, 'Santri', '${r['siswa'] ?? 0}', _yellow, _yellowBg),
      _StatItem(Icons.meeting_room_outlined, 'Kelas', '${r['kelas'] ?? 0}', _greenLight, _greenBg),
      _StatItem(Icons.checklist_outlined, 'Absensi Hari Ini', '${r['absensi_hari_ini'] ?? 0}', _yellow, _yellowBg),
      _StatItem(Icons.grading_outlined, 'Nilai', '${r['nilai'] ?? 0}', _green, _greenBg),
      _StatItem(Icons.calendar_month_outlined, 'Jadwal', '${r['jadwal'] ?? 0}', _greenLight, _greenBg),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          itemBuilder: (_, i) => _ModernStatCard(item: stats[i], index: i),
        );
      },
    );
  }

  Widget _buildDetailGrid(Map<String, dynamic> d) {
    final details = [
      _DetailInfo('Statistik Asatidz', d['guru'] as Map<String, dynamic>? ?? {}, Icons.people_outline, _green),
      _DetailInfo('Statistik Santri', d['siswa'] as Map<String, dynamic>? ?? {}, Icons.person_outline, _yellow),
      _DetailInfo('Absensi Hari Ini', d['absensi'] as Map<String, dynamic>? ?? {}, Icons.checklist_outlined, _greenLight),
      _DetailInfo('Statistik Nilai', d['nilai'] as Map<String, dynamic>? ?? {}, Icons.grading_outlined, _green),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 2 : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cols > 1 ? 1.8 : 2.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: details.length,
          itemBuilder: (_, i) => _ModernDetailCard(info: details[i]),
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(Icons.storage_outlined, 'Master Data', 'Kelola data master', () => widget.onFeatureTap?.call('master-data')),
      _FeatureItem(Icons.calendar_today_outlined, 'Absensi', 'Monitoring absensi', () => widget.onFeatureTap?.call('absensi')),
      _FeatureItem(Icons.grading_outlined, 'Nilai', 'Monitoring nilai', () => widget.onFeatureTap?.call('nilai')),
      _FeatureItem(Icons.description_outlined, 'Rapor', 'Monitoring rapor', () => widget.onFeatureTap?.call('rapor')),
      _FeatureItem(Icons.settings_outlined, 'Pengaturan', 'Pengaturan sistem', () => widget.onFeatureTap?.call('pengaturan'), isSecondary: true),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (_, i) => _buildFeatureCard(features[i]),
    );
  }

  Widget _buildFeatureCard(_FeatureItem item) {
    final gradient = item.isSecondary
        ? [const Color(0xFFFFF8E1), const Color(0xFFFFE082)]
        : [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)];
    final iconColor = item.isSecondary ? const Color(0xFFE65100) : const Color(0xFF1B5E20);
    final shadowColor = item.isSecondary ? _yellow : _green;

    return Material(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(color: shadowColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Icon(item.icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: _green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Sistem Informasi Madrasah PPI',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSecondary;
  _FeatureItem(this.icon, this.title, this.subtitle, this.onTap, {this.isSecondary = false});
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  _StatItem(this.icon, this.label, this.value, this.color, this.bgColor);
}

class _ModernStatCard extends StatelessWidget {
  final _StatItem item;
  final int index;
  const _ModernStatCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: item.color.withOpacity(0.1)),
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
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.label.split(' ').first,
                  style: TextStyle(color: item.color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: item.color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _DetailInfo {
  final String title;
  final Map<String, dynamic> data;
  final IconData icon;
  final Color color;
  _DetailInfo(this.title, this.data, this.icon, this.color);
}

class _ModernDetailCard extends StatelessWidget {
  final _DetailInfo info;
  const _ModernDetailCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: info.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: info.color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icon, color: info.color, size: 20),
              const SizedBox(width: 8),
              Text(
                info.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (info.data.isEmpty)
            Text('Belum ada data', style: TextStyle(color: Colors.grey[400], fontSize: 14))
          else
            ...info.data.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}