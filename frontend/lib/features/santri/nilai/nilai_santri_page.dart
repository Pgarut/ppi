import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';

class NilaiSantriPage extends StatefulWidget {
  const NilaiSantriPage({super.key});

  @override
  State<NilaiSantriPage> createState() => _NilaiSantriPageState();
}

class _NilaiSantriPageState extends State<NilaiSantriPage> {
  final _service = SantriService();
  List<Map<String, dynamic>> _rekap = [];
  List<Map<String, dynamic>> _daftarTA = [];
  List<Map<String, dynamic>> _daftarSem = [];
  double _rataRata = 0;
  bool _loading = true;
  bool _published = true;
  String _message = '';
  String? _selectedTA;
  String? _selectedSem;

  @override
  void initState() {
    super.initState();
    _loadNilai();
  }

  Future<void> _loadNilai() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getNilai(
        semesterId: _selectedSem,
        tahunAjaranId: _selectedTA,
      );
      if (mounted) {
        setState(() {
          _published = result['published'] != false;
          _message = result['message'] as String? ?? '';
          _rekap = (result['rekap'] as List).cast<Map<String, dynamic>>();
          _rataRata = (result['rata_rata_keseluruhan'] ?? 0).toDouble();
          _daftarTA = (result['daftar_tahun_ajaran'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _daftarSem = (result['daftar_semester'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getPredikat(double nilai) {
    if (nilai >= 90) return 'Sangat Baik';
    if (nilai >= 80) return 'Baik';
    if (nilai >= 70) return 'Cukup Baik';
    return 'Belajar Lagi';
  }

  Color _getNilaiColor(double nilai) {
    if (nilai >= 90) return Colors.green;
    if (nilai >= 80) return Colors.amber.shade700;
    if (nilai >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filter Tahun Ajaran & Semester
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.grey200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.filter_list, size: 18, color: AppTheme.primary),
              SizedBox(width: 6),
              Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _selectedTA,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Tahun Ajaran',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Semua', style: TextStyle(fontSize: 12))),
                  ..._daftarTA.map((ta) => DropdownMenuItem(
                    value: '${ta['id']}',
                    child: Text('${ta['nama']}', style: const TextStyle(fontSize: 12)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _selectedTA = v);
                  _selectedSem = null;
                  _loadNilai();
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(
                value: _selectedSem,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Semua', style: TextStyle(fontSize: 12))),
                  ..._daftarSem.map((s) => DropdownMenuItem(
                    value: '${s['id']}',
                    child: Text('${s['nama']}', style: const TextStyle(fontSize: 12)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _selectedSem = v);
                  _loadNilai();
                },
              )),
            ]),
          ]),
        ),
        // Published check
        if (!_published)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _message.isNotEmpty ? _message : 'Nilai belum dipublikasikan',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan hubungi admin atau wali kelas',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Ringkasan
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rata-rata Nilai', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_rataRata.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_getPredikat(_rataRata), style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_rekap.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                const Text('Mapel', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // Detail per Mapel
          Expanded(
            child: _rekap.isEmpty
                ? const Center(child: Text('Belum ada data nilai'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _rekap.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = _rekap[i];
                      final avg = (r['rata_rata'] ?? 0).toDouble();
                      final color = _getNilaiColor(avg);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(r['mapel_nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(avg.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  if ((r['harian'] ?? 0) > 0) _buildNilaiItem('Harian', r['harian']),
                                  if ((r['tugas'] ?? 0) > 0) _buildNilaiItem('Tugas', r['tugas']),
                                  if ((r['uts'] ?? 0) > 0) _buildNilaiItem('UTS', r['uts']),
                                  if ((r['uas'] ?? 0) > 0) _buildNilaiItem('UAS', r['uas']),
                                  if ((r['pts1'] ?? 0) > 0) _buildNilaiItem('PTS1', r['pts1']),
                                  if ((r['pas'] ?? 0) > 0) _buildNilaiItem('PAS', r['pas']),
                                  if ((r['pts2'] ?? 0) > 0) _buildNilaiItem('PTS2', r['pts2']),
                                  if ((r['pat'] ?? 0) > 0) _buildNilaiItem('PAT', r['pat']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildNilaiItem(String label, dynamic value) {
    final v = (value ?? 0).toDouble();
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Text(v.toStringAsFixed(0), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _getNilaiColor(v))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
