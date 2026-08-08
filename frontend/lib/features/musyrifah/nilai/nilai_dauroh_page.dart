import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/musyrifah_service.dart';

class NilaiDaurohPage extends StatefulWidget {
  const NilaiDaurohPage({super.key});

  @override
  State<NilaiDaurohPage> createState() => _NilaiDaurohPageState();
}

class _NilaiDaurohPageState extends State<NilaiDaurohPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  String? _programId;
  String? _search;
  List<Map<String, dynamic>> _programList = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _load();
  }

  Future<void> _loadPrograms() async {
    try {
      final res = await MusyrifahService.getJadwal();
      final programs = <String, Map<String, dynamic>>{};
      for (final j in res) {
        final pid = j['program_id']?.toString();
        if (pid != null && !programs.containsKey(pid)) {
          programs[pid] = {'id': pid, 'nama_program': j['nama_program']?.toString() ?? '-'};
        }
      }
      if (mounted) {
        setState(() => _programList = programs.values.toList());
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.listNilai(
        programId: _programId,
        search: _search,
      );
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
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

  void _showInputNilai(Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      builder: (_) => _InputNilaiDialog(
        existing: existing,
        programList: _programList,
        onSaved: () => _load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Dauroh'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showInputNilai(null),
            tooltip: 'Input Nilai',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama santri...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
              onChanged: (v) {
                setState(() => _search = v.isEmpty ? null : v);
                _load();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.grey300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: _programId,
                  hint: const Text('Semua Program', style: TextStyle(fontSize: 12)),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Program', style: TextStyle(fontSize: 12))),
                    ..._programList.map((p) => DropdownMenuItem(
                      value: p['id']?.toString(),
                      child: Text(p['nama_program']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _programId = v);
                    _load();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_data.isEmpty) {
      return const EmptyState(
        icon: Icons.grading_outlined,
        message: 'Belum ada data nilai',
        actionLabel: 'Input Nilai',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _data.length,
        itemBuilder: (_, i) => _buildNilaiCard(_data[i]),
      ),
    );
  }

  Widget _buildNilaiCard(Map<String, dynamic> nilai) {
    final nama = nilai['santri_nama']?.toString() ?? '-';
    final nis = nilai['nis']?.toString() ?? '-';
    final kelas = nilai['kelas_nama']?.toString() ?? '-';
    final program = nilai['nama_program']?.toString() ?? '-';
    final hafalan = nilai['nilai_hafalan'];
    final bacaan = nilai['nilai_bacaan'];
    final catatan = nilai['catatan']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('NIS: $nis • $kelas', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _showInputNilai(nilai),
                tooltip: 'Edit Nilai',
              ),
            ],
          ),
          const Divider(height: 16),
          Text('Program: $program', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildNilaiChip('Hafalan', hafalan),
              const SizedBox(width: 8),
              _buildNilaiChip('Bacaan', bacaan),
            ],
          ),
          if (catatan != null && catatan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              catatan,
              style: const TextStyle(fontSize: 11, color: AppTheme.grey500, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNilaiChip(String label, dynamic nilai) {
    if (nilai == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$label: -', style: const TextStyle(fontSize: 12, color: AppTheme.grey400)),
      );
    }
    final num = double.tryParse(nilai.toString());
    Color color = AppTheme.grey600;
    if (num != null) {
      if (num >= 80) {
        color = AppTheme.primary;
      } else if (num >= 60) {
        color = AppTheme.orange;
      } else {
        color = AppTheme.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${num?.toStringAsFixed(0) ?? nilai}',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InputNilaiDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> programList;
  final VoidCallback? onSaved;

  const _InputNilaiDialog({this.existing, required this.programList, this.onSaved});

  @override
  State<_InputNilaiDialog> createState() => _InputNilaiDialogState();
}

class _InputNilaiDialogState extends State<_InputNilaiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hafalanCtrl = TextEditingController();
  final _bacaanCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String? _programId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _hafalanCtrl.text = d['nilai_hafalan']?.toString() ?? '';
      _bacaanCtrl.text = d['nilai_bacaan']?.toString() ?? '';
      _catatanCtrl.text = d['catatan']?.toString() ?? '';
      _programId = d['program_id']?.toString();
    }
  }

  @override
  void dispose() {
    _hafalanCtrl.dispose();
    _bacaanCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Nilai' : 'Input Nilai'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEdit) ...[
                  DropdownButtonFormField<String>(
                    value: _programId,
                    decoration: const InputDecoration(
                      labelText: 'Program',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: widget.programList.map((p) => DropdownMenuItem(
                      value: p['id']?.toString(),
                      child: Text(p['nama_program']?.toString() ?? ''),
                    )).toList(),
                    onChanged: (v) => setState(() => _programId = v),
                    validator: (v) => v == null ? 'Pilih program' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _hafalanCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nilai Hafalan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bacaanCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nilai Bacaan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _catatanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final hafalan = double.tryParse(_hafalanCtrl.text);
      final bacaan = double.tryParse(_bacaanCtrl.text);

      if (_isEdit) {
        await MusyrifahService.updateNilai(
          id: widget.existing!['id'] as int,
          nilaiHafalan: hafalan,
          nilaiBacaan: bacaan,
          catatan: _catatanCtrl.text.isNotEmpty ? _catatanCtrl.text : null,
        );
      } else {
        await MusyrifahService.inputNilai(
          programId: int.parse(_programId!),
          santriId: widget.existing?['santri_id'] as int? ?? 0,
          nilaiHafalan: hafalan,
          nilaiBacaan: bacaan,
          catatan: _catatanCtrl.text.isNotEmpty ? _catatanCtrl.text : null,
        );
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
