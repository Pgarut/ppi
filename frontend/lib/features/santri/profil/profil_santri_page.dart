// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/user_model.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getProfil();
      if (mounted) setState(() { _profil = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final displayName = user?.displayName ?? 'Santri';

    return Column(
      children: [
        // ── Header Profil (selalu tampil) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, Color(0x991565C0)]),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  (_profil?['nama'] ?? displayName)[0].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                ],
              ),
              Text(
                _profil?['nama'] ?? displayName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (_profil != null) ...[
                Text('NIS: ${_profil!['nis'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Kelas: ${_profil!['kelas']?['nama'] ?? '-'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ] else ...[
                Text(UserModel.roleDisplayName(user?.role ?? ''), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ],
          ),
        ),
        // ── Konten Body ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _profil != null
                  ? _buildProfilContent()
                  : _buildErrorContent(displayName),
        ),
        // ── Tombol Logout (SELALU tampil di bagian bawah) ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.grey200)),
          ),
          child: SizedBox(
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
              label: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Konten Profil (data berhasil dimuat) ──
  Widget _buildProfilContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Data Pribadi
          _buildSection('Data Pribadi', [
            _buildRowWithIcon('Nama Santri', _profil!['nama'] ?? '-', Icons.person),
            _buildRow('NIS', _profil!['nis'] ?? '-'),
            _buildRow('NISN', _profil!['nisn'] ?? '-'),
            _buildRow('Kelas', _profil!['kelas']?['nama'] ?? '-'),
            _buildRow('Tingkat', _profil!['kelas']?['tingkat'] ?? '-'),
            _buildRow('Wali Kelas', _profil!['wali_kelas'] ?? '-'),
            _buildRow('Tahun Ajaran', _profil!['tahun_ajaran'] ?? '-'),
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
        ],
      ),
    );
  }

  // ── Konten Error (data gagal dimuat) ──
  Widget _buildErrorContent(String displayName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.grey300),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data profil',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.grey700),
            ),
            const SizedBox(height: 8),
            Text(
              _error?.isNotEmpty == true ? _error! : 'Pastikan koneksi internet stabil dan coba lagi.',
              style: const TextStyle(fontSize: 13, color: AppTheme.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadProfil,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            // Tampilkan info dasar dari auth
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.grey200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
              child: Column(
                children: const <Widget>[
                  Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                  SizedBox(height: 8),
                ],
              ),
              ),
            ),
            Text('Nama: $displayName', style: const TextStyle(fontSize: 13, color: AppTheme.grey600)),
          ],
        ),
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

  Widget _buildRowWithIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
