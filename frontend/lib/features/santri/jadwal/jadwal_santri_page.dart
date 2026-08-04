import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';

class JadwalSantriPage extends StatefulWidget {
  const JadwalSantriPage({super.key});

  @override
  State<JadwalSantriPage> createState() => _JadwalSantriPageState();
}

class _JadwalSantriPageState extends State<JadwalSantriPage> {
  final _service = SantriService();
  List<Map<String, dynamic>> _jadwal = [];
  bool _loading = true;
  String? _filterHari;

  final _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getJadwal(hari: _filterHari);
      if (mounted) setState(() { _jadwal = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Jadwal Pelajaran', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryDark,
              )),
              const Spacer(),
              SizedBox(
                width: 140,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filterHari,
                      hint: const Text('Semua Hari', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: [null, ..._hariList].map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(h ?? 'Semua Hari', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) { setState(() => _filterHari = v); _loadJadwal(); },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _jadwal.isEmpty
                  ? const Center(child: Text('Belum ada jadwal'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _jadwal.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final j = _jadwal[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text('${j['hari']?[0] ?? ''}', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(j['mapel_nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${j['guru_nama'] ?? '-'} • ${j['jam_mulai'] ?? ''} - ${j['jam_selesai'] ?? ''}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${j['hari'] ?? ''}', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
