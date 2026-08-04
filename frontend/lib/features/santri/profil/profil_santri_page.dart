import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/santri_service.dart';

class ProfilSantriPage extends StatefulWidget {
  const ProfilSantriPage({super.key});

  @override
  State<ProfilSantriPage> createState() => _ProfilSantriPageState();
}

class _ProfilSantriPageState extends State<ProfilSantriPage> {
  final _service = SantriService();
  Map<String, dynamic>? _profil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    try {
      final data = await _service.getProfil();
      if (mounted) setState(() { _profil = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_profil == null) return const Center(child: Text('Gagal memuat profil'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (_profil!['nama'] ?? '?')[0].toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_profil!['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('NIS: ${_profil!['nis'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Kelas: ${_profil!['kelas']?['nama'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Data Pribadi
          _buildSection('Data Pribadi', [
            _buildRow('NISN', _profil!['nisn'] ?? '-'),
            _buildRow('Jenis Kelamin', _profil!['jenis_kelamin'] == 'L' ? 'Laki-laki' : 'Perempuan'),
            _buildRow('Tempat Lahir', _profil!['tempat_lahir'] ?? '-'),
            _buildRow('Tanggal Lahir', _profil!['tanggal_lahir'] ?? '-'),
            _buildRow('Alamat', _profil!['alamat'] ?? '-'),
            _buildRow('Status', _profil!['status'] ?? '-'),
          ]),
          const SizedBox(height: 16),
          // Data Orang Tua
          _buildSection('Data Orang Tua', [
            _buildRow('No. HP Orang Tua', _profil!['no_hp_ortu'] ?? '-'),
          ]),
          const SizedBox(height: 16),
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await AppUtils.confirm(context,
                  title: 'Yakin ingin logout?',
                  message: 'Anda akan keluar dari sistem.',
                  confirmText: 'Logout',
                  confirmColor: AppTheme.error,
                );
                if (confirm && context.mounted) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
