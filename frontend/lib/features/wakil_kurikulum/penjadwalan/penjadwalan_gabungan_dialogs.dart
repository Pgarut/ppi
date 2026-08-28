part of 'penjadwalan_page.dart';

class _KelolaGabunganDialog extends StatefulWidget {
  final int semesterId;

  const _KelolaGabunganDialog({required this.semesterId});

  @override
  State<_KelolaGabunganDialog> createState() => _KelolaGabunganDialogState();
}

class _KelolaGabunganDialogState extends State<_KelolaGabunganDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await WakilKurikulumService.getKelasGabungan();
      if (mounted) {
        setState(() {
          _items = list.cast<Map<String, dynamic>>().where((g) => g['semester_id'].toString() == widget.semesterId.toString()).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat: $e';
        });
      }
    }
  }

  Future<void> _tambah() async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormGabunganDialog(semesterId: widget.semesterId),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.createKelasGabungan(hasil);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal tambah: $e';
        });
      }
    }
  }

  Future<void> _ubah(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormGabunganDialog(
        semesterId: widget.semesterId,
        nama: item['nama']?.toString() ?? '',
        kelasAwal: (item['kelas_ids'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toSet() ?? <int>{},
      ),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.updateKelasGabungan(id, hasil);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal ubah: $e';
        });
      }
    }
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Gabungan',
      message: 'Hapus gabungan "${item['nama']}"? Jadwal yang sudah dibuat akan dilepas dari gabungan (tidak dihapus).',
    );
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.deleteKelasGabungan(id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal hapus: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kelas Gabungan', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Text(
              'Kelas yang digabung dianggap satu sesi: jika dijadwalkan ke salah satu kelas anggotanya, semua kelas terisi sekaligus tanpa bentrok.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('DAFTAR KELAS GABUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                const Spacer(),
                Text('${_items.length} gabungan', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loading && _items.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
                    : _items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Belum ada kelas gabungan untuk semester ini.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final g = _items[i];
                              final ids = (g['kelas_ids'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
                              final kelasNama = g['kelas_nama']?.toString() ?? '';
                              final subtitle = kelasNama.isNotEmpty ? kelasNama : 'Kelas id: ${ids.join(', ')}';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.group_work, size: 18, color: Colors.indigo),
                                title: Text(g['nama']?.toString() ?? '-', style: const TextStyle(fontSize: 12.5)),
                                subtitle: Text(subtitle, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      tooltip: 'Ubah',
                                      onPressed: _loading ? null : () => _ubah(g),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      tooltip: 'Hapus',
                                      onPressed: _loading ? null : () => _hapus(g),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
            const Divider(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _tambah,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Gabungan Baru'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _FormGabunganDialog extends StatefulWidget {
  final int semesterId;
  final String nama;
  final Set<int> kelasAwal;

  const _FormGabunganDialog({required this.semesterId, this.nama = '', this.kelasAwal = const {}});

  @override
  State<_FormGabunganDialog> createState() => _FormGabunganDialogState();
}

class _FormGabunganDialogState extends State<_FormGabunganDialog> {
  late final TextEditingController _namaCtrl;
  late Set<int> _selected;
  List<Map<String, dynamic>> _kelas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.nama);
    _selected = Set<int>.from(widget.kelasAwal);
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    try {
      final ref = await WakilKurikulumService.getReferensi();
      if (mounted) {
        setState(() {
          _kelas = (ref['kelas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat daftar kelas: $e';
        });
      }
    }
  }

  void _simpan() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama gabungan tidak boleh kosong');
      return;
    }
    if (_selected.length < 2) {
      setState(() => _error = 'Pilih minimal 2 kelas');
      return;
    }
    Navigator.pop(context, {
      'nama': nama,
      'semester_id': widget.semesterId,
      'kelas_ids': _selected.toList()..sort(),
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Gabungan Kelas', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama gabungan', hintText: 'cth: Gabungan X A+B', isDense: true),
            ),
            const SizedBox(height: 8),
            Text('Pilih kelas anggota (minimal 2):', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _kelas.length,
                        itemBuilder: (_, i) {
                          final k = _kelas[i];
                          final id = int.tryParse('${k['id']}');
                          if (id == null) return const SizedBox.shrink();
                          final namaKelas = k['nama']?.toString() ?? 'Kelas';
                          return CheckboxListTile(
                            dense: true,
                            value: _selected.contains(id),
                            title: Text(namaKelas, style: const TextStyle(fontSize: 12.5)),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(id);
                                } else {
                                  _selected.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
