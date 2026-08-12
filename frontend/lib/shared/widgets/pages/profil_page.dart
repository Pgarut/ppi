import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ProfilPage extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfilPage({super.key, this.onLogout});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? _profil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      // Hanya admin yang boleh akses /admin/guru/{id}
      // Role lain tidak perlu load profil dari API admin
      if (user?.role == 'admin' && user?.guruId != null) {
        final guruRes = await ApiClient.get('/admin/guru/${user!.guruId}');
        _profil = guruRes['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // Tidak perlu tampilkan error, cukup tampilkan data dari auth provider
      debugPrint('[ProfilPage] Gagal load profil: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.displayName ?? 'Pengguna';
    final roleDisplay = UserModel.roleDisplayName(user?.role ?? '');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.person, color: AppTheme.primary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(roleDisplay, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500)),
              ),
              if (widget.onLogout != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_profil != null)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Diri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _infoRow('NIP', _profil!['nip']?.toString()),
                  _infoRow('Nama Lengkap', _profil!['nama']?.toString()),
                  _infoRow('Jenis Kelamin', _profil!['jenis_kelamin']?.toString()),
                  _infoRow('Jabatan', _profil!['jabatan']?.toString()),
                  _infoRow('Status', _profil!['status_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif'),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Data profil pengguna', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Username: $name', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
}