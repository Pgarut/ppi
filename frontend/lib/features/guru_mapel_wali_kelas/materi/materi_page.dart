import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/guru_service.dart';

class MateriPageGuru extends StatefulWidget {
  const MateriPageGuru({super.key});

  @override
  State<MateriPageGuru> createState() => _MateriPageGuruState();
}

class _MateriPageGuruState extends State<MateriPageGuru> {
  List<dynamic> _materi = [];
  List<dynamic> _assignments = [];
  bool _loading = true;
  String? _filterKelasId;
  String? _filterMapelId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final materiRes = await GuruService.getMateri(kelasId: _filterKelasId, mapelId: _filterMapelId);
      final assignmentsRes = await GuruService.getMateriAssignments();
      if (mounted) {
        setState(() {
          _materi = (materiRes['items'] as List?) ?? [];
          _assignments = assignmentsRes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppUtils.handleError(context, e, message: 'Gagal memuat data materi');
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleAktif(int id, bool current) async {
    try {
      await GuruService.toggleMateri(id);
      _loadData();
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e);
    }
  }

  Future<void> _deleteMateri(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: const Text('Yakin ingin menghapus materi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await GuruService.deleteMateri(id);
      _loadData();
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? materi}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _MateriDialog(
        assignments: _assignments,
        materi: materi,
      ),
    );
    if (result == true) _loadData();
  }

  List<Map<String, String>> get _kelasOptions {
    final seen = <String>{};
    return _assignments
        .whereType<Map<String, dynamic>>()
        .map<Map<String, String>>((a) => {'id': '${a['kelas_id']}', 'nama': '${a['kelas_nama']}'})
        .where((e) => seen.add(e['id']!))
        .toList();
  }

  List<Map<String, String>> get _mapelOptions {
    final seen = <String>{};
    return _assignments
        .whereType<Map<String, dynamic>>()
        .map<Map<String, String>>((a) => {'id': '${a['mata_pelajaran_id']}', 'nama': '${a['mapel_nama']}'})
        .where((e) => seen.add(e['id']!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Materi Pelajaran', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryDark,
              )),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filterKelasId,
                      hint: const Text('Semua Kelas', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: [null, ..._kelasOptions].map((k) => DropdownMenuItem(
                        value: k?['id'],
                        child: Text(k?['nama'] ?? 'Semua Kelas', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) { setState(() => _filterKelasId = v); _loadData(); },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filterMapelId,
                      hint: const Text('Semua Mapel', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: [null, ..._mapelOptions].map((m) => DropdownMenuItem(
                        value: m?['id'],
                        child: Text(m?['nama'] ?? 'Semua Mapel', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) { setState(() => _filterMapelId = v); _loadData(); },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _materi.isEmpty
                  ? const Center(child: Text('Belum ada materi'))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _materi.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildMateriCard(_materi[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMateriCard(Map<String, dynamic> m) {
    final isActive = m['is_aktif'] == 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['judul'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${m['mapel_nama'] ?? '-'} • ${m['kelas_nama'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
                      if (m['pertemuan'] != null)
                        Text('Pertemuan ${m['pertemuan']}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                      if (m['link_youtube'] != null)
                        const Row(
                          children: [
                            Icon(Icons.play_circle_outline, size: 12, color: Colors.red),
                            SizedBox(width: 4),
                            Text('Video tersedia', style: TextStyle(fontSize: 11, color: Colors.red)),
                          ],
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (v) => _toggleAktif(m['id'], isActive),
                  activeColor: AppTheme.primary,
                ),
              ],
            ),
            if (m['deskripsi'] != null && (m['deskripsi'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(m['deskripsi'], style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (m['link_url'] != null)
                  TextButton.icon(
                    onPressed: () => _openLink(m['link_url']),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Buka Link', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddEditDialog(materi: m),
                  icon: const Icon(Icons.edit, size: 18),
                  color: AppTheme.grey500,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deleteMateri(m['id']),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DIALOG TAMBAH / EDIT MATERI
// ═══════════════════════════════════════════════

class _MateriDialog extends StatefulWidget {
  final List<dynamic> assignments;
  final Map<String, dynamic>? materi;

  const _MateriDialog({required this.assignments, this.materi});

  @override
  State<_MateriDialog> createState() => _MateriDialogState();
}

class _MateriDialogState extends State<_MateriDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulC;
  late TextEditingController _deskripsiC;
  late TextEditingController _linkC;
  late TextEditingController _linkYoutubeC;
  late TextEditingController _pertemuanC;
  String? _kelasId;
  String? _mapelId;
  bool _isAktif = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.materi;
    _judulC = TextEditingController(text: m?['judul'] ?? '');
    _deskripsiC = TextEditingController(text: m?['deskripsi'] ?? '');
    _linkC = TextEditingController(text: m?['link_url'] ?? '');
    _linkYoutubeC = TextEditingController(text: m?['link_youtube'] ?? '');
    _pertemuanC = TextEditingController(text: m?['pertemuan'] ?? '');
    _kelasId = m?['kelas_id']?.toString();
    _mapelId = m?['mata_pelajaran_id']?.toString();
    _isAktif = (m?['is_aktif'] ?? 1) == 1;
  }

  @override
  void dispose() {
    _judulC.dispose();
    _deskripsiC.dispose();
    _linkC.dispose();
    _linkYoutubeC.dispose();
    _pertemuanC.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _kelasOptions {
    final seen = <String>{};
    return widget.assignments
        .map<Map<String, String>>((a) => {'id': '${a['kelas_id']}', 'nama': '${a['kelas_nama']}'})
        .where((e) => seen.add(e['id']!))
        .toList();
  }

  List<Map<String, String>> get _mapelOptions {
    final seen = <String>{};
    return widget.assignments
        .map<Map<String, String>>((a) => {'id': '${a['mata_pelajaran_id']}', 'nama': '${a['mapel_nama']}'})
        .where((e) => seen.add(e['id']!))
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = {
        'judul': _judulC.text.trim(),
        'deskripsi': _deskripsiC.text.trim().isEmpty ? null : _deskripsiC.text.trim(),
        'link_url': _linkC.text.trim(),
        'link_youtube': _linkYoutubeC.text.trim().isEmpty ? null : _linkYoutubeC.text.trim(),
        'pertemuan': _pertemuanC.text.trim().isEmpty ? null : _pertemuanC.text.trim(),
        'kelas_id': int.parse(_kelasId!),
        'mata_pelajaran_id': int.parse(_mapelId!),
        'is_aktif': _isAktif ? 1 : 0,
      };

      if (widget.materi != null) {
        await GuruService.updateMateri(widget.materi!['id'], body);
      } else {
        await GuruService.createMateri(body);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppUtils.handleError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.materi != null ? 'Edit Materi' : 'Tambah Materi'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _kelasId,
                decoration: const InputDecoration(labelText: 'Kelas *', border: OutlineInputBorder()),
                items: _kelasOptions.map((k) => DropdownMenuItem(
                  value: k['id'], child: Text(k['nama']!),
                )).toList(),
                onChanged: (v) => setState(() => _kelasId = v),
                validator: (v) => v == null ? 'Pilih kelas' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mapelId,
                decoration: const InputDecoration(labelText: 'Mata Pelajaran *', border: OutlineInputBorder()),
                items: _mapelOptions.map((m) => DropdownMenuItem(
                  value: m['id'], child: Text(m['nama']!),
                )).toList(),
                onChanged: (v) => setState(() => _mapelId = v),
                validator: (v) => v == null ? 'Pilih mata pelajaran' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _judulC,
                decoration: const InputDecoration(labelText: 'Judul *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pertemuanC,
                decoration: const InputDecoration(
                  labelText: 'Pertemuan',
                  hintText: 'mis. 1, 2, Pertemuan 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkC,
                decoration: const InputDecoration(
                  labelText: 'Link Google Drive *',
                  hintText: 'https://drive.google.com/...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Link wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkYoutubeC,
                decoration: const InputDecoration(
                  labelText: 'Link YouTube (opsional)',
                  hintText: 'https://youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiC,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Aktif'),
                subtitle: Text(_isAktif ? 'Materi ditampilkan ke siswa' : 'Materi tersembunyi'),
                value: _isAktif,
                onChanged: (v) => setState(() => _isAktif = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
