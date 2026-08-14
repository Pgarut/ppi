import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_utils.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_table.dart';
import 'program_form_page.dart';

class ProgramListPage extends StatefulWidget {
  const ProgramListPage({super.key});

  @override
  State<ProgramListPage> createState() => _ProgramListPageState();
}

class _ProgramListPageState extends State<ProgramListPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DaurohService.listProgram(
        page: _page,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _data = (res['items'] as List).cast<Map<String, dynamic>>();
          _totalPages = res['pagination']?['total_pages'] ?? 1;
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

  Future<void> _delete(int id, String nama) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Program',
      message: 'Yakin hapus program "$nama"?',
    );
    if (!ok) return;
    try {
      await DaurohService.deleteProgram(id);
      _load(refresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  void _showForm({Map<String, dynamic>? edit}) {
    showDialog(
      context: context,
      builder: (_) => ProgramFormPage(
        editData: edit,
        onSaved: () => _load(refresh: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Program Kegiatan at-Ta\'wid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (_data.isNotEmpty)
                    Text(
                      '${_data.length} data',
                      style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                    ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Cari program...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _load(refresh: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Program'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DaurohTable(
              columns: const [
                DaurohTableColumn(key: 'nama_program', label: 'Nama Program', width: 200),
                DaurohTableColumn(key: 'jenis_program', label: 'Jenis', width: 100),
                DaurohTableColumn(key: 'jenis_dauroh', label: 'at-Ta\'wid', width: 100),
                DaurohTableColumn(key: 'keterangan', label: 'Keterangan', width: 200),
                DaurohTableColumn(key: 'jumlah_jadwal', label: 'Jadwal', width: 80),
                DaurohTableColumn(key: 'is_aktif', label: 'Status', width: 80),
              ],
              data: _data,
              isLoading: _loading,
              error: _error,
              currentPage: _page,
              totalPages: _totalPages,
              onPrevious: _page > 1
                  ? () {
                      setState(() => _page--);
                      _load();
                    }
                  : null,
              onNext: _page < _totalPages
                  ? () {
                      setState(() => _page++);
                      _load();
                    }
                  : null,
              onEdit: (row) => _showForm(edit: row),
              onDelete: (row) => _delete(row['id'] as int, row['nama_program']?.toString() ?? ''),
              displayFn: (key, value, row) {
                if (key == 'jenis_program') return value == 'khusus' ? 'Khusus' : 'Kelas';
                if (key == 'jenis_dauroh') return value == 'tahfidz' ? 'Tahfidz' : 'Murojaah';
                if (key == 'is_aktif') return value == 1 ? 'Aktif' : 'Nonaktif';
                return value?.toString() ?? '-';
              },
            ),
          ),
        ],
      ),
    );
  }
}
