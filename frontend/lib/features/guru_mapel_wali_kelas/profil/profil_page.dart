import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class ProfilPageGuru extends StatefulWidget {
  const ProfilPageGuru({super.key});

  @override
  State<ProfilPageGuru> createState() => _ProfilPageGuruState();
}

class _ProfilPageGuruState extends State<ProfilPageGuru> {
  Map<String, dynamic>? _profil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get('/auth/me');
      final user = res['data'] as Map<String, dynamic>? ?? {};
      final guruId = user['guru_id'];
      if (guruId != null) {
        final guruRes = await ApiClient.get('/admin/guru/$guruId');
        _profil = guruRes['data'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profil Asatidz', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_profil == null)
          _buildPlaceholder()
        else
          _buildProfil(),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Data profil belum tersedia', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Gunakan menu Wali Kelas untuk data santri', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProfil() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.person, size: 40, color: Colors.green[700]),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profil!['nama']?.toString() ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_profil!['nip']?.toString() ?? '-', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            _infoRow('NIP', _profil!['nip']?.toString()),
            _infoRow('Nama Lengkap', _profil!['nama']?.toString()),
            _infoRow('Jenis Kelamin', _profil!['jenis_kelamin']?.toString()),
            _infoRow('Tempat Lahir', _profil!['tempat_lahir']?.toString()),
            _infoRow('Tanggal Lahir', _profil!['tanggal_lahir']?.toString()),
            _infoRow('Alamat', _profil!['alamat']?.toString()),
            _infoRow('No. HP', _profil!['no_hp']?.toString()),
            _infoRow('Email', _profil!['email']?.toString()),
            _infoRow('Status', _profil!['status']?.toString()),
          ],
        ),
      ),
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
