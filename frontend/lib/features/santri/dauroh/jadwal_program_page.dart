import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/dauroh_santri_service.dart';

class JadwalProgramPage extends StatefulWidget {
  const JadwalProgramPage({super.key});

  @override
  State<JadwalProgramPage> createState() => _JadwalProgramPageState();
}

class _JadwalProgramPageState extends State<JadwalProgramPage> {
  final _service = DaurohSantriService();
  List<Map<String, dynamic>> _program = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _program = await _service.getProgram();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Jadwal Program',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_program.isEmpty)
            _buildEmptyCard('Belum terdaftar di program at-Ta\'wid')
          else
            ..._program.map((p) => _buildProgramCard(p)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.grey500, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final nama = program['nama_program']?.toString() ?? '-';
    final jenis = program['jenis_program']?.toString() ?? '-';
    final dauroh = program['jenis_dauroh']?.toString() ?? '-';
    final keterangan = program['keterangan']?.toString();
    final hari = program['hari']?.toString() ?? '-';
    final jamMulai = program['jam_mulai']?.toString() ?? '';
    final jamSelesai = program['jam_selesai']?.toString() ?? '';
    final musyrifah = program['musyrifah_nama']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jenis.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dauroh.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            if (keterangan != null && keterangan.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                keterangan,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, '$hari, $jamMulai - $jamSelesai'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.person, 'Musyrifah: $musyrifah'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.grey500),
          ),
        ),
      ],
    );
  }
}
