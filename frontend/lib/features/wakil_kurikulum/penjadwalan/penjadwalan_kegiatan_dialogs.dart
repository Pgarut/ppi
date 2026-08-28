part of 'penjadwalan_page.dart';

class _KelolaKegiatanDialog extends StatefulWidget {
  final List<Map<String, dynamic>> awal;

  const _KelolaKegiatanDialog({required this.awal});

  @override
  State<_KelolaKegiatanDialog> createState() => _KelolaKegiatanDialogState();
}

class _KelolaKegiatanDialogState extends State<_KelolaKegiatanDialog> {
  late final List<Map<String, dynamic>> _items;
  final TextEditingController _namaCtrl = TextEditingController();
  String _tipe = 'kegiatan';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items = widget.awal.map((k) => Map<String, dynamic>.from(k)).toList();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final list = await WakilKurikulumService.getKegiatanTetap();
      if (mounted) setState(() => _items = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _tambah() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama kegiatan tidak boleh kosong');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.createKegiatanTetap(nama, _tipe);
      _namaCtrl.clear();
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal tambah: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _ubah(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _FormKegiatanDialog(
        title: 'Ubah Kegiatan',
        nama: item['nama']?.toString() ?? '',
        tipe: item['tipe']?.toString() == 'istirahat' ? 'istirahat' : 'kegiatan',
      ),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.updateKegiatanTetap(id, hasil['nama']!, hasil['tipe']!);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal ubah: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Kegiatan',
      message: 'Hapus "${item['nama']}" dari daftar kegiatan tetap?',
    );
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.deleteKegiatanTetap(id);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal hapus: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kegiatan Tetap', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Text(
              'Kegiatan ini bisa di-drag ke tabel jadwal. Drag item yang ada, atau tambah kegiatan baru di bawah.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Belum ada kegiatan tetap.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final k = _items[i];
                          final isIstirahat = k['tipe'] == 'istirahat';
                          final nama = k['nama']?.toString() ?? '-';
                          final color = isIstirahat ? Colors.orange : Colors.blue;
                          return ListTile(
                            dense: true,
                            leading: Icon(isIstirahat ? Icons.coffee : Icons.school, size: 18, color: color[700]),
                            title: Text(nama, style: const TextStyle(fontSize: 12.5)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: 'Ubah',
                                  onPressed: _loading ? null : () => _ubah(k),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  tooltip: 'Hapus',
                                  onPressed: _loading ? null : () => _hapus(k),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                DropdownButton<String>(
                  value: _tipe,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'istirahat', child: Text('Istirahat', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: _loading ? null : (v) => setState(() => _tipe = v!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _namaCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      labelText: 'Nama kegiatan baru',
                      hintText: 'cth: Shalat Dzuhur Berjamaah',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _tambah(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add, size: 18),
                  tooltip: 'Tambah',
                  onPressed: _loading ? null : _tambah,
                ),
              ],
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

class _FormKegiatanDialog extends StatefulWidget {
  final String title;
  final String nama;
  final String tipe;

  const _FormKegiatanDialog({required this.title, this.nama = '', this.tipe = 'kegiatan'});

  @override
  State<_FormKegiatanDialog> createState() => _FormKegiatanDialogState();
}

class _FormKegiatanDialogState extends State<_FormKegiatanDialog> {
  late final TextEditingController _namaCtrl;
  late String _tipe;
  String? _error;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.nama);
    _tipe = widget.tipe;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama kegiatan tidak boleh kosong');
      return;
    }
    Navigator.pop(context, {'nama': nama, 'tipe': _tipe});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama kegiatan', isDense: true),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tipe,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan')),
                DropdownMenuItem(value: 'istirahat', child: Text('Istirahat')),
              ],
              onChanged: (v) => setState(() => _tipe = v!),
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
