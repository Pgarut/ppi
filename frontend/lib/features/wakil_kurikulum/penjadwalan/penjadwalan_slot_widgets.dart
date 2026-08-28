part of 'penjadwalan_page.dart';

class _WaktuDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? mulai;
  final String? selesai;
  final String note;

  const _WaktuDialog({
    required this.title,
    required this.confirmLabel,
    this.mulai,
    this.selesai,
    required this.note,
  });

  @override
  State<_WaktuDialog> createState() => _WaktuDialogState();
}

class _WaktuDialogState extends State<_WaktuDialog> {
  late final TextEditingController _mulaiCtrl;
  late final TextEditingController _selesaiCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mulaiCtrl = TextEditingController(text: widget.mulai ?? '');
    _selesaiCtrl = TextEditingController(text: widget.selesai ?? '');
  }

  @override
  void dispose() {
    _mulaiCtrl.dispose();
    _selesaiCtrl.dispose();
    super.dispose();
  }

  static bool _valid(String t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t);

  static int _toMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _simpan() {
    final mulai = _mulaiCtrl.text.trim();
    final selesai = _selesaiCtrl.text.trim();
    if (!_valid(mulai) || !_valid(selesai)) {
      setState(() => _error = 'Format waktu harus HH:MM (contoh: 07:00)');
      return;
    }
    if (_toMin(mulai) >= _toMin(selesai)) {
      setState(() => _error = 'Jam mulai harus lebih awal dari jam selesai');
      return;
    }
    Navigator.pop(context, {'mulai': mulai, 'selesai': selesai});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mulaiCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Mulai', hintText: '07:00', isDense: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: TextField(
                    controller: _selesaiCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Selesai', hintText: '07:40', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.note, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _HariCheckboxRow extends StatelessWidget {
  final List<String> nilai;
  final ValueChanged<List<String>> onChanged;
  static const _semuaHari = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];

  const _HariCheckboxRow({required this.nilai, required this.onChanged});

  String _getHariLabel() {
    if (nilai.isEmpty) return 'Pilih Hari';
    if (nilai.length == _semuaHari.length) return 'Semua Hari';
    final abbr = nilai.map((h) => h.substring(0, 2)).join(', ');
    return abbr;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: () async {
          final hasil = await showDialog<List<String>>(
            context: context,
            builder: (ctx) => _HariMultiSelectDialog(
              selectedHari: List.from(nilai),
              semuaHari: _semuaHari,
            ),
          );
          if (hasil != null) onChanged(hasil);
        },
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getHariLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: nilai.isEmpty ? Colors.grey[500] : Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HariMultiSelectDialog extends StatefulWidget {
  final List<String> selectedHari;
  final List<String> semuaHari;

  const _HariMultiSelectDialog({required this.selectedHari, required this.semuaHari});

  @override
  State<_HariMultiSelectDialog> createState() => _HariMultiSelectDialogState();
}

class _HariMultiSelectDialogState extends State<_HariMultiSelectDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedHari);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Hari Aktif', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _selected.length == widget.semuaHari.length,
              onChanged: (v) {
                setState(() {
                  _selected = v == true ? List.from(widget.semuaHari) : [];
                });
              },
              title: const Text('Semua Hari', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
            ...widget.semuaHari.map((hari) {
              final isSelected = _selected.contains(hari);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(hari);
                    } else {
                      _selected.remove(hari);
                    }
                  });
                },
                title: Text(hari, style: const TextStyle(fontSize: 13)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
