import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/admin_service.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  int _selectedTab = 0;

  final _tabs = [
    _TabCfg('Tahun Ajaran', 'tahun-ajaran', Icons.calendar_month_outlined, ['nama', 'tanggal_mulai', 'tanggal_selesai', 'is_aktif'],
        ['Nama', 'Tgl Mulai', 'Tgl Selesai', 'Aktif']),
    _TabCfg('Semester', 'semester', Icons.layers_outlined, ['tahun_ajaran_id', 'nama', 'is_aktif'], ['Tahun Ajaran ID', 'Nama', 'Aktif']),
    _TabCfg('Jurusan', 'jurusan', Icons.category_outlined, ['nama', 'kode'], ['Nama', 'Kode']),
    _TabCfg('Tingkat', 'tingkat', Icons.stairs_outlined, ['nama', 'jenjang'], ['Nama', 'Jenjang']),
    _TabCfg('Kelas', 'kelas', Icons.meeting_room_outlined, ['nama', 'tingkat_id', 'jurusan_id', 'tahun_ajaran_id'],
        ['Nama', 'Tingkat ID', 'Jurusan ID', 'Thn Ajaran ID']),
    _TabCfg('Mata Pelajaran', 'mata-pelajaran', Icons.book_outlined, ['nama', 'kode'], ['Nama', 'Kode']),
    _TabCfg('Asatidz', 'guru', Icons.people_outline, ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'],
        ['NIP', 'Nama', 'JK', 'Jabatan', 'Status']),
    _TabCfg('Wali Kelas', 'wali-kelas', Icons.supervisor_account_outlined, ['nip', 'nama', 'kelas_nama', 'jumlah_siswa', 'jabatan'],
        ['NIP', 'Nama Asatidz', 'Kelas', 'Jml Santri', 'Jabatan']),
    _TabCfg('Asatidz BK', 'guru-bk-list', Icons.psychology_outlined, ['nip', 'nama', 'jabatan'],
        ['NIP', 'Nama Asatidz', 'Jabatan']),
    _TabCfg('Santri', 'siswa', Icons.person_outline, ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'nama_ayah', 'nama_ibu', 'pekerjaan_ayah', 'pekerjaan_ibu', 'whatsapp', 'username', 'password', 'status'],
        ['NIS', 'NISN', 'Nama', 'JK', 'Kelas', 'Nama Ayah', 'Nama Ibu', 'Pekerjaan Ayah', 'Pekerjaan Ibu', 'WhatsApp', 'Username', 'Password', 'Status']),
    _TabCfg('Ruangan', 'ruangan', Icons.room_outlined, ['nama', 'kapasitas'], ['Nama', 'Kapasitas']),
  ];

  final Map<int, List<Map<String, dynamic>>> _data = {};
  final Map<int, bool> _loading = {};
  final Map<int, int> _page = {};
  final Map<int, int> _totalPages = {};
  final Map<int, String?> _error = {};
  final Map<int, TextEditingController> _searchCtrl = {};

  // Filter untuk Santri (idx == 9)
  String? _filterTingkat;
  String? _filterKelas;
  List<Map<String, dynamic>> _tingkatList = [];
  List<Map<String, dynamic>> _kelasList = [];
  final ValueNotifier<bool> _passwordObscure = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _tabs.length; i++) {
      _data[i] = [];
      _loading[i] = false;
      _page[i] = 1;
      _totalPages[i] = 1;
      _searchCtrl[i] = TextEditingController();
    }
    _load(0);
    _loadSantriFilters();
  }

  @override
  void dispose() {
    for (final c in _searchCtrl.values) { c.dispose(); }
    super.dispose();
  }

  // Load Tingkat & Kelas untuk filter Santri
  Future<void> _loadSantriFilters() async {
    try {
      final tingkatRes = await AdminService.list('tingkat', perPage: 100);
      _tingkatList = (tingkatRes['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _tingkatList = [];
    }
    try {
      final kelasRes = await AdminService.list('kelas', perPage: 100);
      _kelasList = (kelasRes['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _kelasList = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _load(int idx, {bool refresh = false}) async {
    if (refresh) _page[idx] = 1;
    setState(() { _loading[idx] = true; _error[idx] = null; });
    try {
      if (idx == 7) {
        final res = await ApiClient.get('/admin/wali-kelas');
        if (mounted) { setState(() {
          _data[idx] = (res['data'] as List).cast<Map<String, dynamic>>();
          _totalPages[idx] = 1;
          _loading[idx] = false;
        }); }
        return;
      }
      if (idx == 8) {
        final res = await ApiClient.get('/admin/guru-bk-list');
        if (mounted) { setState(() {
          _data[idx] = (res['data'] as List).cast<Map<String, dynamic>>();
          _totalPages[idx] = 1;
          _loading[idx] = false;
        }); }
        return;
      }
      final filters = <String, String>{};
      if (idx == 9) {
        if (_filterTingkat != null) filters['tingkat_id'] = _filterTingkat!;
        if (_filterKelas != null) filters['kelas_id'] = _filterKelas!;
      }
      final res = await AdminService.list(_tabs[idx].resource,
          page: _page[idx]!, perPage: 20, search: _searchCtrl[idx]!.text, filters: filters);
      if (mounted) { setState(() {
        _data[idx] = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages[idx] = res['pagination']?['total_pages'] ?? 1;
        _loading[idx] = false;
      }); }
    } catch (e) {
      if (mounted) setState(() { _error[idx] = e.toString(); _loading[idx] = false; });
    }
  }

  Future<void> _showForm(int idx, {Map<String, dynamic>? edit}) async {
    final cfg = _tabs[idx];
    final formKey = GlobalKey<FormState>();
    final ctrls = <String, TextEditingController>{};
    for (final col in cfg.columns) {
      ctrls[col] = TextEditingController(text: edit?[col]?.toString() ?? '');
    }
    _passwordObscure.value = true;

    String? selectedAktif;
    if (idx == 0 || idx == 1) {
      final val = edit?['is_aktif'];
      selectedAktif = val == 1 ? 'Aktif' : (val == 0 ? 'Tidak Aktif' : null);
    }

    String? selectedNamaSemester;
    if (idx == 1) {
      final val = edit?['nama'];
      selectedNamaSemester = (val == 'Ganjil' || val == 'Genap') ? val : null;
    }

    int? selectedTaId;
    List<Map<String, dynamic>> taList = _data[0] ?? [];
    if ((idx == 1 || idx == 4) && taList.isEmpty) {
      AdminService.list('tahun-ajaran', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[0] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }
    if ((idx == 1 || idx == 4) && edit != null) {
      selectedTaId = int.tryParse(edit['tahun_ajaran_id']?.toString() ?? '');
    }

    int? selectedTingkatId;
    int? selectedJurusanId;

    List<Map<String, dynamic>> tingkatList = _data[3] ?? [];
    if (idx == 4 && tingkatList.isEmpty) {
      AdminService.list('tingkat', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[3] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }

    List<Map<String, dynamic>> jurusanList = _data[2] ?? [];
    if (idx == 4 && jurusanList.isEmpty) {
      AdminService.list('jurusan', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[2] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }

    if (idx == 4 && edit != null) {
      selectedTingkatId = int.tryParse(edit['tingkat_id']?.toString() ?? '');
      selectedJurusanId = int.tryParse(edit['jurusan_id']?.toString() ?? '');
    }

    Set<int> selectedKelasIds = {};
    List<Map<String, dynamic>> kelasList = _data[4] ?? [];
    if ((idx == 5 || idx == 6 || idx == 9) && kelasList.isEmpty) {
      final res = await AdminService.list('kelas', page: 1, perPage: 100);
      _data[4] = (res['items'] as List).cast<Map<String, dynamic>>();
      kelasList = _data[4]!;
    }
    if (idx == 5 && edit != null) {
      AdminService.getById('mata-pelajaran', edit['id'] as int).then((res) {
        final mapelId = res['id'];
        ApiClient.get('/admin/mapel-kelas/$mapelId/kelas').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { selectedKelasIds = ids.toSet(); });
        });
      });
    }

    // ── Siswa (idx 9) ──
    String? selectedSiswaJk;
    int? selectedSiswaKelasId;
    String? selectedSiswaStatus;
    if (idx == 9) {
      if (edit != null) {
        selectedSiswaJk = edit['jenis_kelamin']?.toString();
        selectedSiswaKelasId = int.tryParse(edit['kelas_id']?.toString() ?? '');
        if (selectedSiswaKelasId != null && !kelasList.any((k) => k['id'] == selectedSiswaKelasId)) {
          selectedSiswaKelasId = null;
        }
        final rawStatus = edit['status']?.toString() ?? '';
        if (rawStatus == 'Aktif' || rawStatus.toLowerCase() == 'aktif') {
          selectedSiswaStatus = 'Aktif';
        } else if (rawStatus == 'Tidak Aktif' || rawStatus.toLowerCase() == 'tidak_aktif' || rawStatus.toLowerCase() == 'tidak aktif') {
          selectedSiswaStatus = 'Tidak Aktif';
        } else if (rawStatus == 'Pindah' || rawStatus.toLowerCase() == 'pindah') {
          selectedSiswaStatus = 'Pindah';
        } else {
          selectedSiswaStatus = rawStatus.isNotEmpty ? rawStatus : null;
        }
      }
    }

    // ── Guru (idx 6) ──
    String? selectedJk;
    Set<String> selectedJabatanSet = {};
    Set<int> selectedGuruMapelIds = {};
    Set<int> selectedGuruKelasIds = {};
    String? selectedStatusGuru;
    final guruUsernameCtrl = TextEditingController(text: edit?['_username']?.toString() ?? '');
    final guruPasswordCtrl = TextEditingController(text: edit?['_password']?.toString() ?? '');

    List<Map<String, dynamic>> mapelList = _data[5] ?? [];
    if (idx == 6) {
      if (kelasList.isEmpty) {
        AdminService.list('kelas', page: 1, perPage: 100).then((res) {
          if (mounted) setState(() { _data[4] = (res['items'] as List).cast<Map<String, dynamic>>(); });
        });
      }
      if (mapelList.isEmpty) {
        AdminService.list('mata-pelajaran', page: 1, perPage: 100).then((res) {
          if (mounted) setState(() { _data[5] = (res['items'] as List).cast<Map<String, dynamic>>(); });
        });
      }

      if (edit != null) {
        selectedJk = edit['jenis_kelamin']?.toString();
        selectedStatusGuru = edit['status_aktif'] == 1 ? 'Aktif' : (edit['status_aktif'] == 0 ? 'Tidak Aktif' : null);
        final jabatanStr = edit['jabatan']?.toString() ?? '';
        if (jabatanStr.isNotEmpty) selectedJabatanSet = jabatanStr.split(',').map((s) => s.trim()).toSet();

        final gid = edit['id'] as int;
        ApiClient.get('/admin/guru-mapel/$gid/mapel').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { selectedGuruMapelIds = ids.toSet(); });
        });
        ApiClient.get('/admin/guru-kelas/$gid/kelas').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { selectedGuruKelasIds = ids.toSet(); });
        });
      }
    }

    if (!mounted) return Future.value();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit != null ? 'Edit ${cfg.label}' : 'Tambah ${cfg.label}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (idx == 9)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DataCard(
                      header: Row(children: [
                        Icon(Icons.person_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Data Pribadi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _FormRow(children: [
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['nis']!,
                              label: 'NIS',
                              icon: Icons.badge_outlined,
                              hint: 'Nomor Induk Santri',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['nisn']!,
                              label: 'NISN',
                              icon: Icons.numbers_outlined,
                              hint: 'Nomor Induk Santri Nasional',
                              optional: true,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _ModernField(
                          controller: ctrls['nama']!,
                          label: 'Nama Santri',
                          icon: Icons.text_fields,
                          hint: 'Nama lengkap santri',
                        ),
                        const SizedBox(height: 16),
                        _FormRow(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSiswaJk,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Kelamin',
                                prefixIcon: Icon(Icons.wc_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                              ],
                              onChanged: (v) => selectedSiswaJk = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSiswaStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                                DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                                DropdownMenuItem(value: 'Pindah', child: Text('Pindah')),
                              ],
                              onChanged: (v) => selectedSiswaStatus = v,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    DataCard(
                      header: Row(children: [
                        Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Penempatan Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                      child: DropdownButtonFormField<int>(
                        value: selectedSiswaKelasId,
                        decoration: const InputDecoration(
                          labelText: 'Kelas',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: (kelasList.isEmpty ? [] : kelasList).map((k) => DropdownMenuItem<int>(
                          value: k['id'] as int,
                          child: Text(k['nama']?.toString() ?? ''),
                        )).toList(),
                        onChanged: (v) => selectedSiswaKelasId = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DataCard(
                      header: Row(children: [
                        Icon(Icons.family_restroom_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Data Orang Tua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _FormRow(children: [
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['nama_ayah']!,
                              label: 'Nama Ayah',
                              icon: Icons.man_outlined,
                              hint: 'Nama lengkap ayah',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['nama_ibu']!,
                              label: 'Nama Ibu',
                              icon: Icons.woman_outlined,
                              hint: 'Nama lengkap ibu',
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _FormRow(children: [
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['pekerjaan_ayah']!,
                              label: 'Pekerjaan Ayah',
                              icon: Icons.work_outlined,
                              hint: 'Pekerjaan ayah',
                              optional: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernField(
                              controller: ctrls['pekerjaan_ibu']!,
                              label: 'Pekerjaan Ibu',
                              icon: Icons.work_outlined,
                              hint: 'Pekerjaan ibu',
                              optional: true,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _ModernField(
                          controller: ctrls['whatsapp']!,
                          label: 'Nomor WhatsApp',
                          icon: Icons.phone_outlined,
                          hint: '08xxxxxxxxxx',
                          keyboardType: TextInputType.phone,
                          optional: true,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    DataCard(
                      header: Row(children: [
                        Icon(Icons.lock_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Akun Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        _ModernField(
                          controller: ctrls['username']!,
                          label: 'Username',
                          icon: Icons.alternate_email,
                          hint: 'Username untuk login',
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<bool>(
                          valueListenable: _passwordObscure,
                          builder: (_, obscure, __) {
                            return TextFormField(
                              controller: ctrls['password'],
                              obscureText: obscure,
                              validator: (edit != null)
                                  ? null
                                  : (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                              decoration: InputDecoration(
                                labelText: edit != null ? 'Password (kosongkan jika tidak diubah)' : 'Password',
                                hintText: edit != null ? '••••••' : 'Masukkan password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                  onPressed: () => _passwordObscure.value = !_passwordObscure.value,
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: (edit != null) ? 'Opsional' : null,
                                suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.grey400),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ],
                )
              else if (idx == 0)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _ModernField(controller: ctrls['nama']!, label: 'Nama Tahun Ajaran', icon: Icons.calendar_month_outlined),
                  const SizedBox(height: 16),
                  _FormRow(children: [
                    Expanded(child: _DateField(controller: ctrls['tanggal_mulai']!, label: 'Tanggal Mulai', ctx: ctx)),
                    const SizedBox(width: 16),
                    Expanded(child: _DateField(controller: ctrls['tanggal_selesai']!, label: 'Tanggal Selesai', ctx: ctx)),
                  ]),
                  const SizedBox(height: 16),
                  _DropdownField<String>(
                    value: selectedAktif,
                    label: 'Status',
                    icon: Icons.toggle_on_outlined,
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                    ],
                    onChanged: (v) => selectedAktif = v,
                  ),
                ])
              else if (idx == 1)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.layers_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Semester', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _DropdownField<String>(
                        value: selectedNamaSemester,
                        label: 'Semester',
                        icon: Icons.numbers,
                        items: const [
                          DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                          DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                        ],
                        onChanged: (v) => selectedNamaSemester = v,
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<int>(
                        value: selectedTaId,
                        label: 'Tahun Ajaran',
                        icon: Icons.calendar_month_outlined,
                        items: (taList.isEmpty ? [] : taList).map((ta) => DropdownMenuItem<int>(
                          value: ta['id'] as int,
                          child: Text(ta['nama']?.toString() ?? ''),
                        )).toList(),
                        onChanged: (v) => selectedTaId = v,
                      ),
                      const SizedBox(height: 16),
                      _DropdownField<String>(
                        value: selectedAktif,
                        label: 'Status',
                        icon: Icons.toggle_on_outlined,
                        items: const [
                          DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                          DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                        ],
                        onChanged: (v) => selectedAktif = v,
                      ),
                    ]),
                  ),
                ])
              else if (idx == 2)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.category_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Jurusan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _ModernField(controller: ctrls['nama']!, label: 'Nama Jurusan', icon: Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _ModernField(controller: ctrls['kode']!, label: 'Kode Jurusan', icon: Icons.code_outlined, hint: 'Contoh: IPA, IPS, AGAMA'),
                    ]),
                  ),
                ])
              else if (idx == 3)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.stairs_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Tingkat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _ModernField(controller: ctrls['nama']!, label: 'Nama Tingkat', icon: Icons.badge_outlined, hint: 'Contoh: X, XI, XII'),
                      const SizedBox(height: 16),
                      _ModernField(controller: ctrls['jenjang']!, label: 'Jenjang', icon: Icons.school_outlined, hint: 'Contoh: SMA/SMK/MA'),
                    ]),
                  ),
                ])
              else if (idx == 4)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _ModernField(controller: ctrls['nama']!, label: 'Nama Kelas', icon: Icons.badge_outlined, hint: 'Contoh: X IPA 1'),
                      const SizedBox(height: 16),
                      _FormRow(children: [
                        Expanded(
                          child: _DropdownField<int>(
                            value: selectedTingkatId,
                            label: 'Tingkat',
                            icon: Icons.stairs_outlined,
                            items: (tingkatList.isEmpty ? [] : tingkatList).map((t) => DropdownMenuItem<int>(
                              value: t['id'] as int,
                              child: Text(t['nama']?.toString() ?? ''),
                            )).toList(),
                            onChanged: (v) => selectedTingkatId = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DropdownField<int>(
                            value: selectedJurusanId,
                            label: 'Jurusan',
                            icon: Icons.category_outlined,
                            items: (jurusanList.isEmpty ? [] : jurusanList).map((j) => DropdownMenuItem<int>(
                              value: j['id'] as int,
                              child: Text(j['nama']?.toString() ?? ''),
                            )).toList(),
                            onChanged: (v) => selectedJurusanId = v,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _DropdownField<int>(
                        value: selectedTaId,
                        label: 'Tahun Ajaran',
                        icon: Icons.calendar_month_outlined,
                        items: (taList.isEmpty ? [] : taList).map((ta) => DropdownMenuItem<int>(
                          value: ta['id'] as int,
                          child: Text(ta['nama']?.toString() ?? ''),
                        )).toList(),
                        onChanged: (v) => selectedTaId = v,
                      ),
                    ]),
                  ),
                ])
              else if (idx == 5)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.book_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Mata Pelajaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _ModernField(controller: ctrls['nama']!, label: 'Nama Mapel', icon: Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _FormRow(children: [
                        Expanded(
                          child: _ModernField(controller: ctrls['kode']!, label: 'Kode Mapel', icon: Icons.code_outlined, hint: 'Contoh: MTK-WAJIB'),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if (kelasList.isEmpty)
                        const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
                      else
                        ...kelasList.map((k) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                          value: selectedKelasIds.contains(k['id'] as int),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) { selectedKelasIds.add(k['id'] as int); }
                              else { selectedKelasIds.remove(k['id'] as int); }
                            });
                          },
                        )),
                    ]),
                  ),
                ])
              else if (idx == 6)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.people_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Asatidz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _FormRow(children: [
                        Expanded(child: _ModernField(controller: ctrls['nip']!, label: 'NIP', icon: Icons.badge_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _ModernField(controller: ctrls['nama']!, label: 'Nama Asatidz', icon: Icons.text_fields)),
                      ]),
                      const SizedBox(height: 16),
                      _FormRow(children: [
                        Expanded(
                          child: _DropdownField<String>(
                            value: selectedJk,
                            label: 'Jenis Kelamin',
                            icon: Icons.wc_outlined,
                            items: const [
                              DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                              DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                            ],
                            onChanged: (v) => selectedJk = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DropdownField<String>(
                            value: selectedStatusGuru,
                            label: 'Status',
                            icon: Icons.flag_outlined,
                            items: const [
                              DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                              DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                            ],
                            onChanged: (v) => selectedStatusGuru = v,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Jabatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey600)),
                        const SizedBox(height: 4),
                        ...['Asatidz Mapel', 'Wali Kelas', 'Kepala Madrasah', 'Wakil Kurikulum', 'Asatidz BK'].map((j) {
                          final val = j == 'Asatidz Mapel' ? 'guru_mapel' : j == 'Wali Kelas' ? 'wali_kelas' : j == 'Kepala Madrasah' ? 'kepala_sekolah' : j == 'Wakil Kurikulum' ? 'wakil_kurikulum' : 'guru_bk';
                          return CheckboxListTile(
                            dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                            title: Text(j, style: const TextStyle(fontSize: 14)),
                            value: selectedJabatanSet.contains(val),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) { selectedJabatanSet.add(val); }
                                else { selectedJabatanSet.remove(val); }
                              });
                            },
                          );
                        }),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.lock_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Akun Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: _FormRow(children: [
                      Expanded(child: _ModernField(controller: guruUsernameCtrl, label: 'Username', icon: Icons.person_outline)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: guruPasswordCtrl,
                          obscureText: true,
                          decoration: _inputDecoration('Password', Icons.lock_outline),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.book_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Mata Pelajaran yang Diampu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if (mapelList.isEmpty)
                        const Text('Memuat data mapel...', style: TextStyle(color: AppTheme.grey500))
                      else
                        ...mapelList.map((m) => CheckboxListTile(
                          dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                          title: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                          value: selectedGuruMapelIds.contains(m['id'] as int),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) { selectedGuruMapelIds.add(m['id'] as int); }
                              else { selectedGuruMapelIds.remove(m['id'] as int); }
                            });
                          },
                        )),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Kelas yang Diajar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if (kelasList.isEmpty)
                        const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
                      else
                        ...kelasList.map((k) => CheckboxListTile(
                          dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                          title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                          value: selectedGuruKelasIds.contains(k['id'] as int),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) { selectedGuruKelasIds.add(k['id'] as int); }
                              else { selectedGuruKelasIds.remove(k['id'] as int); }
                            });
                          },
                        )),
                    ]),
                  ),
                ])
              else if (idx == 10)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  DataCard(
                    header: Row(children: [
                      Icon(Icons.room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Data Ruangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _ModernField(controller: ctrls['nama']!, label: 'Nama Ruangan', icon: Icons.badge_outlined, hint: 'Contoh: Aula, Lab. Komputer, Kelas 1A'),
                      const SizedBox(height: 16),
                      _ModernField(controller: ctrls['kapasitas']!, label: 'Kapasitas', icon: Icons.people_outlined, hint: 'Jumlah maksimal orang'),
                    ]),
                  ),
                ])
              else
                for (final col in cfg.columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: ctrls[col],
                      decoration: InputDecoration(
                        labelText: col == 'nama' ? 'Nama' : col,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final body = <String, dynamic>{};
              for (final col in cfg.columns) {
                if ((idx == 0 || idx == 1) && col == 'is_aktif') {
                  body[col] = selectedAktif == 'Aktif' ? 1 : 0;
                } else if ((idx == 1 || idx == 4) && col == 'tahun_ajaran_id') {
                  body[col] = selectedTaId;
                } else if (idx == 1 && col == 'nama') {
                  body[col] = selectedNamaSemester;
                } else if (idx == 4 && col == 'tingkat_id') {
                  body[col] = selectedTingkatId;
                } else if (idx == 4 && col == 'jurusan_id') {
                  body[col] = selectedJurusanId;
                } else if (idx == 6 && col == 'jenis_kelamin') {
                  body[col] = selectedJk;
                } else if (idx == 6 && col == 'jabatan') {
                  body[col] = selectedJabatanSet.join(',');
                } else if (idx == 6 && col == 'status_aktif') {
                  body[col] = selectedStatusGuru == 'Aktif' ? 1 : 0;
                } else if (idx == 9 && col == 'jenis_kelamin') {
                  body[col] = selectedSiswaJk;
                } else if (idx == 9 && col == 'kelas_id') {
                  body[col] = selectedSiswaKelasId;
                } else if (idx == 9 && col == 'status') {
                  body[col] = selectedSiswaStatus;
                } else if (idx == 9 && col == 'password' && edit != null && ctrls[col]!.text.isEmpty) {
                  // skip empty password on edit
                } else {
                  body[col] = ctrls[col]!.text;
                }
              }
              if (idx == 6) {
                body['username'] = guruUsernameCtrl.text;
                body['password'] = guruPasswordCtrl.text;
              }
              try {
                int? savedId;
                if (edit != null) {
                  await AdminService.update(cfg.resource, edit['id'] as int, body);
                  savedId = edit['id'] as int;
                } else {
                  final result = await AdminService.create(cfg.resource, body);
                  savedId = result['id'] as int?;
                }
                if (idx == 5 && savedId != null) {
                  await ApiClient.put('/admin/mapel-kelas/$savedId/kelas', body: {
                    'kelas_ids': selectedKelasIds.toList(),
                  });
                }
                if (idx == 6 && savedId != null) {
                  await ApiClient.put('/admin/guru-mapel/$savedId/mapel', body: {
                    'mapel_ids': selectedGuruMapelIds.toList(),
                  });
                  await ApiClient.put('/admin/guru-kelas/$savedId/kelas', body: {
                    'kelas_ids': selectedGuruKelasIds.toList(),
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load(idx, refresh: true);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int idx, int id) async {
    final ok = await AppUtils.confirm(context, title: 'Hapus', message: 'Yakin hapus ${_tabs[idx].label} ini?');
    if (!ok) return;
    try {
      await AdminService.delete(_tabs[idx].resource, id);
      _load(idx, refresh: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _downloadTemplate() {
    try {
      ApiClient.get('/admin/siswa/template').then((res) {
        final data = res['data'] as Map<String, dynamic>;
        final base64Str = data['base64'] as String;
        final bytes = base64Decode(base64Str);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'template_siswa.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }).catchError((e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download template: $e')));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleUploadSiswa() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
        return;
      }

      final base64Str = base64Encode(bytes);
      final previewRes = await ApiClient.post('/admin/siswa/preview', body: {
        'file_base64': base64Str,
      });
      final data = previewRes['data'] as Map<String, dynamic>;
      final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      _showPreviewDialog(rows, base64Str);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  void _showPreviewDialog(List<Map<String, dynamic>> rows, String base64Str) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preview Data (${rows.length} baris)'),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rows.where((r) => r['valid'] == true).length} valid, ${rows.where((r) => r['valid'] != true).length} error',
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? AppTheme.error : AppTheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NIS: ${r['nis']}  |  ${r['nama']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'JK: ${r['jenis_kelamin']}  |  Kelas: ${r['kelas_nama']}  |  Status: ${r['status']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                        ),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          if (rows.any((r) => r['valid'] == true))
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final validRows = rows.where((r) => r['valid'] == true).map((r) => {
                  'nis': r['nis'],
                  'nisn': r['nisn'],
                  'nama': r['nama'],
                  'jenis_kelamin': r['jenis_kelamin'],
                  'kelas_id': r['kelas_id'],
                  'status': r['status'],
                }).toList();

                try {
                  final res = await ApiClient.post('/admin/siswa/bulk', body: {'data': validRows});
                  final result = res['data'] as Map<String, dynamic>;
                  final inserted = result['inserted'];
                  final errors = (result['errors'] as List?) ?? [];
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                  ));
                  _load(9, refresh: true);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
                }
              },
              child: Text('Simpan ${rows.where((r) => r['valid'] == true).length} Data'),
            ),
        ],
      ),
    );
  }

  void _downloadMapelTemplate() {
    try {
      ApiClient.get('/admin/mata-pelajaran/template').then((res) {
        final data = res['data'] as Map<String, dynamic>;
        final base64Str = data['base64'] as String;
        final bytes = base64Decode(base64Str);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'template_mata_pelajaran.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }).catchError((e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download template: $e')));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleUploadMapel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
        return;
      }

      final base64Str = base64Encode(bytes);
      final previewRes = await ApiClient.post('/admin/mata-pelajaran/preview', body: {
        'file_base64': base64Str,
      });
      final data = previewRes['data'] as Map<String, dynamic>;
      final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      _showMapelPreviewDialog(rows, base64Str);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  void _showMapelPreviewDialog(List<Map<String, dynamic>> rows, String base64Str) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preview Data Mapel (${rows.length} baris)'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rows.where((r) => r['valid'] == true).length} valid, ${rows.where((r) => r['valid'] != true).length} error',
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? AppTheme.error : AppTheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nama: ${r['nama']}  |  Kode: ${r['kode'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          if (rows.any((r) => r['valid'] == true))
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final validRows = rows.where((r) => r['valid'] == true).map((r) => {
                  'nama': r['nama'],
                  'kode': r['kode'],
                }).toList();

                try {
                  final res = await ApiClient.post('/admin/mata-pelajaran/bulk', body: {'data': validRows});
                  final result = res['data'] as Map<String, dynamic>;
                  final inserted = result['inserted'];
                  final errors = (result['errors'] as List?) ?? [];
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                  ));
                  _load(5, refresh: true);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
                }
              },
              child: Text('Simpan ${rows.where((r) => r['valid'] == true).length} Data'),
            ),
        ],
      ),
    );
  }

  void _downloadGuruTemplate() {
    try {
      ApiClient.get('/admin/guru/template').then((res) {
        final data = res['data'] as Map<String, dynamic>;
        final base64Str = data['base64'] as String;
        final bytes = base64Decode(base64Str);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'template_guru.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }).catchError((e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download template: $e')));
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleUploadGuru() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
        return;
      }

      final base64Str = base64Encode(bytes);
      final previewRes = await ApiClient.post('/admin/guru/preview', body: {
        'file_base64': base64Str,
      });
      final data = previewRes['data'] as Map<String, dynamic>;
      final rows = (data['rows'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      _showGuruPreviewDialog(rows, base64Str);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  void _showGuruPreviewDialog(List<Map<String, dynamic>> rows, String base64Str) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Preview Data Asatidz (${rows.length} baris)'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rows.where((r) => r['valid'] == true).length} valid, ${rows.where((r) => r['valid'] != true).length} error',
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? AppTheme.error : AppTheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.05) : AppTheme.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NIP: ${r['nip']}  |  ${r['nama']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'JK: ${r['jenis_kelamin']}  |  Jabatan: ${r['jabatan']}  |  Status: ${r['status_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif'}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                        ),
                        Text(
                          'Username: ${r['username']}  |  Password: ${r['password'] ?? ''}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                        ),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            ),
                          ),
                      ]),
                    ),
                  ]),
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          if (rows.any((r) => r['valid'] == true))
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final validRows = rows.where((r) => r['valid'] == true).map((r) => {
                  'nip': r['nip'],
                  'nama': r['nama'],
                  'jenis_kelamin': r['jenis_kelamin'],
                  'jabatan': r['jabatan'],
                  'status_aktif': r['status_aktif'],
                  'username': r['username'],
                  'password': r['password'],
                }).toList();

                try {
                  final res = await ApiClient.post('/admin/guru/bulk', body: {'data': validRows});
                  final result = res['data'] as Map<String, dynamic>;
                  final inserted = result['inserted'];
                  final errors = (result['errors'] as List?) ?? [];
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                  ));
                  _load(6, refresh: true);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
                }
              },
              child: Text('Simpan ${rows.where((r) => r['valid'] == true).length} Data'),
            ),
        ],
      ),
    );
  }

  String _displayValue(String col, dynamic val, {int? idx, Map<String, dynamic>? row}) {
    if (val == null) return '-';
    if (col == 'password') return '••••••';
    if (col == 'is_aktif' || col == 'status_aktif') return val == 1 ? 'Ya' : 'Tidak';
    if (col == 'jenis_kelamin') return val == 'L' ? 'Laki-laki' : 'Perempuan';
    if (col == 'kelas_id' && (idx == 5 || idx == 9)) {
      final kelasList = _data[4] ?? [];
      final k = kelasList.cast<Map<String, dynamic>?>().firstWhere(
        (k) => k?['id'] == val, orElse: () => null);
      return k?['nama']?.toString() ?? val.toString();
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data'), automaticallyImplyLeading: false),
      body: Row(children: [
        Container(
          width: 220,
          decoration: const BoxDecoration(color: AppTheme.grey50, border: Border(right: BorderSide(color: AppTheme.grey200))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Menu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.grey500)),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _tabs.length,
              itemBuilder: (_, i) {
                final t = _tabs[i];
                final isActive = _selectedTab == i;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(t.icon, size: 20, color: isActive ? AppTheme.primary : AppTheme.grey500),
                    title: Text(t.label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : null, color: isActive ? null : AppTheme.grey600)),
                    selected: isActive,
                    onTap: () {
                      setState(() => _selectedTab = i);
                      if (_data[i]!.isEmpty && _loading[i] == false) _load(i);
                    },
                  ),
                );
              },
            )),
          ]),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    final idx = _selectedTab;
    final cfg = _tabs[idx];
    final totalData = _data[idx]?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cfg.label, style: Theme.of(context).textTheme.titleLarge),
            if (totalData > 0) Text('$totalData data', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
          ]),
          if (idx != 7 && idx != 8) Row(children: [
            if (idx == 5) ...[
              OutlinedButton.icon(
                onPressed: _downloadMapelTemplate,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Template'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _handleUploadMapel,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Excel'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 12),
            ],
            if (idx == 6) ...[
              OutlinedButton.icon(
                onPressed: _downloadGuruTemplate,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Template'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _handleUploadGuru,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Excel'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 12),
            ],
            if (idx == 9) ...[
              // Filter Tingkat
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
                      value: _filterTingkat,
                      hint: const Text('Tingkat', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: _tingkatList.map((t) => DropdownMenuItem(
                        value: '${t['id']}',
                        child: Text('${t['nama']}', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) {
                        setState(() {
                          _filterTingkat = v;
                          _filterKelas = null;
                        });
                        _load(idx, refresh: true);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Kelas
              SizedBox(
                width: 160,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filterKelas,
                      hint: const Text('Kelas', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      items: _kelasList.where((k) {
                        if (_filterTingkat == null) return true;
                        return k['tingkat_id'].toString() == _filterTingkat;
                      }).map((k) => DropdownMenuItem(
                        value: '${k['id']}',
                        child: Text('${k['nama']}', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (v) {
                        setState(() => _filterKelas = v);
                        _load(idx, refresh: true);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Template'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _handleUploadSiswa,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Excel'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(width: 12),
            ],
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchCtrl[idx],
                decoration: _searchDeco(),
                onSubmitted: (_) => _load(idx, refresh: true),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showForm(idx),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _buildTable(idx, cfg)),
      ]),
    );
  }

  Widget _buildTable(int idx, _TabCfg cfg) {
    if (_loading[idx] == true) return const Center(child: CircularProgressIndicator());
    if (_error[idx] != null) return Center(child: Text(_error[idx]!, style: const TextStyle(color: AppTheme.error)));
    if (_data[idx]!.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        message: 'Belum ada data.',
      );
    }

    final showActions = !(idx == 7 || idx == 8);
    const colWidth = 150.0;
    final actionsWidth = showActions ? 80.0 : 0.0;
    final totalContentWidth = cfg.columns.length * colWidth + actionsWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(children: [
        // ── HEADER ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            border: Border(bottom: BorderSide(color: AppTheme.grey200)),
          ),
          child: SizedBox(
            width: totalContentWidth,
            child: Row(children: [
              ...cfg.displayCols.map((h) => SizedBox(
                width: colWidth,
                child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700)),
              )),
              if (showActions) const SizedBox(
                width: 80,
                child: Text('Aksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700)),
              ),
            ]),
          ),
        ),
        // ── BODY ──
        Expanded(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalContentWidth,
            child: ListView.separated(
              itemCount: _data[idx]!.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final row = _data[idx]![i];
                return Container(
                  color: i.isEven ? null : AppTheme.grey50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(children: [
                    ...cfg.columns.asMap().entries.map((e) {
                      final col = cfg.columns[e.key];
                      final val = _displayValue(col, row[col], idx: idx, row: row);
                      return SizedBox(
                        width: colWidth,
                        child: Text(val, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                      );
                    }),
                    if (showActions) SizedBox(
                      width: actionsWidth,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.grey500),
                          onPressed: () => _showForm(idx, edit: row),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                          onPressed: () => _delete(idx, row['id'] as int),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    ),
                  ]),
                );
              },
            ),
          ),
        )),
        // ── PAGINATION ──
        if (_totalPages[idx]! > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(top: BorderSide(color: AppTheme.grey200)),
            ),
            child: PaginationRow(
              currentPage: _page[idx]!,
              totalPages: _totalPages[idx]!,
              onPrevious: _page[idx]! > 1 ? () {
                _page[idx] = _page[idx]! - 1;
                _load(idx);
              } : null,
              onNext: _page[idx]! < _totalPages[idx]! ? () {
                _page[idx] = _page[idx]! + 1;
                _load(idx);
              } : null,
            ),
          ),
      ]),
    );
  }
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool optional;
  final TextInputType? keyboardType;
  const _ModernField({required this.controller, required this.label, required this.icon, this.hint, this.optional = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: optional ? null : (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixText: optional ? 'Opsional' : null,
        suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.grey400),
      ),
    );
  }
}

InputDecoration _searchDeco() {
  return const InputDecoration(
    hintText: 'Cari...',
    prefixIcon: Icon(Icons.search, size: 20),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    filled: true,
    fillColor: Colors.white,
  );
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return AppInputDecoration.standard(label, icon);
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({required this.value, required this.label, required this.icon, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _inputDecoration(label, icon),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final BuildContext ctx;
  const _DateField({required this.controller, required this.label, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, size: 20),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true,
        fillColor: Colors.white,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: ctx,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
        );
        if (date != null) {
          controller.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}

class _TabCfg {
  final String label;
  final String resource;
  final IconData icon;
  final List<String> columns;
  final List<String> displayCols;
  _TabCfg(this.label, this.resource, this.icon, this.columns, this.displayCols);
}
