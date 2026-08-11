import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/musyrifah_service.dart';

class ProfilMusyrifahPage extends StatefulWidget {
  const ProfilMusyrifahPage({super.key});

  @override
  State<ProfilMusyrifahPage> createState() => _ProfilMusyrifahPageState();
}

class _ProfilMusyrifahPageState extends State<ProfilMusyrifahPage> {
  Map<String, dynamic>? _profil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await MusyrifahService.getProfil();
      if (mounted) setState(() { _profil = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Musyrifah'), automaticallyImplyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _profil == null
              ? const Center(child: Text('Gagal memuat profil'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAvatar() {
    final nama = _profil?['nama']?.toString() ?? 'M';
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'M',
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(Icons.person_outline, 'Nama', _profil?['nama']?.toString() ?? '-'),
          _buildInfoTile(Icons.badge_outlined, 'NIPMUS', _profil?['nipmus']?.toString() ?? '-'),
          _buildInfoTile(Icons.wc_outlined, 'Jenis Kelamin', _profil?['jenis_kelamin']?.toString() == 'L' ? 'Laki-laki' : 'Perempuan'),
          _buildInfoTile(Icons.school_outlined, 'Status Pendidikan', _profil?['status_pendidikan']?.toString() == 'selesai' ? 'Selesai (Sarjana)' : 'Mahasiswa'),
          if (_profil?['gelar']?.toString().isNotEmpty == true)
            _buildInfoTile(Icons.emoji_events_outlined, 'Gelar', _profil!['gelar'].toString()),
          _buildInfoTile(Icons.account_circle_outlined, 'Username', _profil?['username']?.toString() ?? '-'),
          _buildInfoTile(
            Icons.toggle_on_outlined,
            'Status',
            _profil?['is_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.grey500),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.grey500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
