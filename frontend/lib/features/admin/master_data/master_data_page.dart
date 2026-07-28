import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/admin_service.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/confirm_dialog.dart';

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
    _TabCfg('Guru', 'guru', Icons.people_outline, ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'],
        ['NIP', 'Nama', 'JK', 'Jabatan', 'Status']),
    _TabCfg('Wali Kelas', 'wali-kelas', Icons.supervisor_account_outlined, ['nip', 'nama', 'kelas_nama', 'jumlah_siswa', 'jabatan'],
        ['NIP', 'Nama Guru', 'Kelas', 'Jml Siswa', 'Jabatan']),
    _TabCfg('Guru BK', 'guru-bk-list', Icons.psychology_outlined, ['nip', 'nama', 'jabatan'],
        ['NIP', 'Nama Guru', 'Jabatan']),
    _TabCfg('Siswa', 'siswa', Icons.person_outline, ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'status'],
        ['NIS', 'NISN', 'Nama', 'JK', 'Kelas', 'Status']),
    _TabCfg('Ruangan', 'ruangan', Icons.room_outlined, ['nama', 'kapasitas'], ['Nama', 'Kapasitas']),
  ];

  final Map<int, List<Map<String, dynamic>>> _data = {};
  final Map<int, bool> _loading = {};
  final Map<int, int> _page = {};
  final Map<int, int> _totalPages = {};
  final Map<int, String?> _error = {};
  final Map<int, TextEditingController> _searchCtrl = {};

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
  }

  @override
  void dispose() {
    for (final c in _searchCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _load(int idx, {bool refresh = false}) async {
    if (refresh) _page[idx] = 1;
    setState(() { _loading[idx] = true; _error[idx] = null; });
    try {
      if (idx == 7) {
        final res = await ApiClient.get('/admin/wali-kelas');
        if (mounted) setState(() {
          _data[idx] = (res['data'] as List).cast<Map<String, dynamic>>();
          _totalPages[idx] = 1;
          _loading[idx] = false;
        });
        return;
      }
      if (idx == 8) {
        final res = await ApiClient.get('/admin/guru-bk-list');
        if (mounted) setState(() {
          _data[idx] = (res['data'] as List).cast<Map<String, dynamic>>();
          _totalPages[idx] = 1;
          _loading[idx] = false;
        });
        return;
      }
      final filters = <String, String>{};
      final res = await AdminService.list(_tabs[idx].resource,
          page: _page[idx]!, perPage: 20, search: _searchCtrl[idx]!.text, filters: filters);
      if (mounted) setState(() {
        _data[idx] = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages[idx] = res['pagination']?['total_pages'] ?? 1;
        _loading[idx] = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error[idx] = e.toString(); _loading[idx] = false; });
    }
  }

  Future<void> _showForm(int idx, {Map<String, dynamic>? edit}) {
    final cfg = _tabs[idx];
    final ctrls = <String, TextEditingController>{};
    for (final col in cfg.columns) {
      ctrls[col] = TextEditingController(text: edit?[col]?.toString() ?? '');
    }

    String? _selectedAktif;
    if (idx == 0 || idx == 1) {
      final val = edit?['is_aktif'];
      _selectedAktif = val == 1 ? 'Aktif' : (val == 0 ? 'Tidak Aktif' : null);
    }

    String? _selectedNamaSemester;
    if (idx == 1) {
      final val = edit?['nama'];
      _selectedNamaSemester = (val == 'Ganjil' || val == 'Genap') ? val : null;
    }

    int? _selectedTaId;
    List<Map<String, dynamic>> taList = _data[0] ?? [];
    if ((idx == 1 || idx == 4) && taList.isEmpty) {
      AdminService.list('tahun-ajaran', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[0] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }
    if ((idx == 1 || idx == 4) && edit != null) {
      _selectedTaId = int.tryParse(edit['tahun_ajaran_id']?.toString() ?? '');
    }

    int? _selectedTingkatId;
    int? _selectedJurusanId;

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
      _selectedTingkatId = int.tryParse(edit['tingkat_id']?.toString() ?? '');
      _selectedJurusanId = int.tryParse(edit['jurusan_id']?.toString() ?? '');
    }

    Set<int> _selectedKelasIds = {};
    List<Map<String, dynamic>> kelasList = _data[4] ?? [];
    if ((idx == 5 || idx == 6 || idx == 9) && kelasList.isEmpty) {
      AdminService.list('kelas', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[4] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }
    if (idx == 5 && edit != null) {
      AdminService.getById('mata-pelajaran', edit['id'] as int).then((res) {
        final mapelId = res['id'];
        ApiClient.get('/admin/mapel-kelas/$mapelId/kelas').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { _selectedKelasIds = ids.toSet(); });
        });
      });
    }

    // ── Siswa (idx 9) ──
    String? _selectedSiswaJk;
    int? _selectedSiswaKelasId;
    String? _selectedSiswaStatus;
    if (idx == 9) {
      if (edit != null) {
        _selectedSiswaJk = edit['jenis_kelamin']?.toString();
        _selectedSiswaKelasId = int.tryParse(edit['kelas_id']?.toString() ?? '');
        _selectedSiswaStatus = edit['status']?.toString();
      }
    }

    // ── Guru (idx 6) ──
    String? _selectedJk;
    Set<String> _selectedJabatanSet = {};
    Set<int> _selectedGuruMapelIds = {};
    Set<int> _selectedGuruKelasIds = {};
    String? _selectedStatusGuru;
    final _guruUsernameCtrl = TextEditingController(text: edit?['_username']?.toString() ?? '');
    final _guruPasswordCtrl = TextEditingController(text: edit?['_password']?.toString() ?? '');

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
        _selectedJk = edit['jenis_kelamin']?.toString();
        _selectedStatusGuru = edit['status_aktif'] == 1 ? 'Aktif' : (edit['status_aktif'] == 0 ? 'Tidak Aktif' : null);
        final jabatanStr = edit['jabatan']?.toString() ?? '';
        if (jabatanStr.isNotEmpty) _selectedJabatanSet = jabatanStr.split(',').map((s) => s.trim()).toSet();

        final gid = edit['id'] as int;
        ApiClient.get('/admin/guru-mapel/$gid/mapel').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { _selectedGuruMapelIds = ids.toSet(); });
        });
        ApiClient.get('/admin/guru-kelas/$gid/kelas').then((r) {
          final ids = (r['data'] as List).cast<int>();
          if (mounted) setState(() { _selectedGuruKelasIds = ids.toSet(); });
        });
      }
    }

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit != null ? 'Edit ${cfg.label}' : 'Tambah ${cfg.label}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (idx == 9)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FormCard(title: 'Data Pribadi', icon: Icons.person_outline, children: [
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
                            value: _selectedSiswaJk,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Kelamin',
                              prefixIcon: Icon(Icons.wc_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                              DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                            ],
                            onChanged: (v) => _selectedSiswaJk = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSiswaStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.flag_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                              DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                              DropdownMenuItem(value: 'Pindah', child: Text('Pindah')),
                            ],
                            onChanged: (v) => _selectedSiswaStatus = v,
                          ),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    _FormCard(title: 'Penempatan Kelas', icon: Icons.meeting_room_outlined, children: [
                      DropdownButtonFormField<int>(
                        value: _selectedSiswaKelasId,
                        decoration: const InputDecoration(
                          labelText: 'Kelas',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                        ),
                        items: (kelasList.isEmpty ? [] : kelasList).map((k) => DropdownMenuItem<int>(
                          value: k['id'] as int,
                          child: Text(k['nama']?.toString() ?? ''),
                        )).toList(),
                        onChanged: (v) => _selectedSiswaKelasId = v,
                      ),
                    ]),
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
                    value: _selectedAktif,
                    label: 'Status',
                    icon: Icons.toggle_on_outlined,
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                    ],
                    onChanged: (v) => _selectedAktif = v,
                  ),
                ])
              else if (idx == 1)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Semester', icon: Icons.layers_outlined, children: [
                    _DropdownField<String>(
                      value: _selectedNamaSemester,
                      label: 'Semester',
                      icon: Icons.numbers,
                      items: const [
                        DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                        DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                      ],
                      onChanged: (v) => _selectedNamaSemester = v,
                    ),
                    const SizedBox(height: 16),
                    _DropdownField<int>(
                      value: _selectedTaId,
                      label: 'Tahun Ajaran',
                      icon: Icons.calendar_month_outlined,
                      items: (taList.isEmpty ? [] : taList).map((ta) => DropdownMenuItem<int>(
                        value: ta['id'] as int,
                        child: Text(ta['nama']?.toString() ?? ''),
                      )).toList(),
                      onChanged: (v) => _selectedTaId = v,
                    ),
                    const SizedBox(height: 16),
                    _DropdownField<String>(
                      value: _selectedAktif,
                      label: 'Status',
                      icon: Icons.toggle_on_outlined,
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                      ],
                      onChanged: (v) => _selectedAktif = v,
                    ),
                  ]),
                ])
              else if (idx == 2)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Jurusan', icon: Icons.category_outlined, children: [
                    _ModernField(controller: ctrls['nama']!, label: 'Nama Jurusan', icon: Icons.badge_outlined),
                    const SizedBox(height: 16),
                    _ModernField(controller: ctrls['kode']!, label: 'Kode Jurusan', icon: Icons.code_outlined, hint: 'Contoh: IPA, IPS, AGAMA'),
                  ]),
                ])
              else if (idx == 3)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Tingkat', icon: Icons.stairs_outlined, children: [
                    _ModernField(controller: ctrls['nama']!, label: 'Nama Tingkat', icon: Icons.badge_outlined, hint: 'Contoh: X, XI, XII'),
                    const SizedBox(height: 16),
                    _ModernField(controller: ctrls['jenjang']!, label: 'Jenjang', icon: Icons.school_outlined, hint: 'Contoh: SMA/SMK/MA'),
                  ]),
                ])
              else if (idx == 4)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Kelas', icon: Icons.meeting_room_outlined, children: [
                    _ModernField(controller: ctrls['nama']!, label: 'Nama Kelas', icon: Icons.badge_outlined, hint: 'Contoh: X IPA 1'),
                    const SizedBox(height: 16),
                    _FormRow(children: [
                      Expanded(
                        child: _DropdownField<int>(
                          value: _selectedTingkatId,
                          label: 'Tingkat',
                          icon: Icons.stairs_outlined,
                          items: (tingkatList.isEmpty ? [] : tingkatList).map((t) => DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text(t['nama']?.toString() ?? ''),
                          )).toList(),
                          onChanged: (v) => _selectedTingkatId = v,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DropdownField<int>(
                          value: _selectedJurusanId,
                          label: 'Jurusan',
                          icon: Icons.category_outlined,
                          items: (jurusanList.isEmpty ? [] : jurusanList).map((j) => DropdownMenuItem<int>(
                            value: j['id'] as int,
                            child: Text(j['nama']?.toString() ?? ''),
                          )).toList(),
                          onChanged: (v) => _selectedJurusanId = v,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _DropdownField<int>(
                      value: _selectedTaId,
                      label: 'Tahun Ajaran',
                      icon: Icons.calendar_month_outlined,
                      items: (taList.isEmpty ? [] : taList).map((ta) => DropdownMenuItem<int>(
                        value: ta['id'] as int,
                        child: Text(ta['nama']?.toString() ?? ''),
                      )).toList(),
                      onChanged: (v) => _selectedTaId = v,
                    ),
                  ]),
                ])
              else if (idx == 5)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Mata Pelajaran', icon: Icons.book_outlined, children: [
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
                  const SizedBox(height: 16),
                  _FormCard(title: 'Kelas', icon: Icons.meeting_room_outlined, children: [
                    if (kelasList.isEmpty)
                      const Text('Memuat data kelas...', style: TextStyle(color: Colors.grey))
                    else
                      ...kelasList.map((k) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                        value: _selectedKelasIds.contains(k['id'] as int),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) _selectedKelasIds.add(k['id'] as int);
                            else _selectedKelasIds.remove(k['id'] as int);
                          });
                        },
                      )),
                  ]),
                ])
              else if (idx == 6)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Asatidz', icon: Icons.people_outline, children: [
                    _FormRow(children: [
                      Expanded(child: _ModernField(controller: ctrls['nip']!, label: 'NIP', icon: Icons.badge_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _ModernField(controller: ctrls['nama']!, label: 'Nama Asatidz', icon: Icons.text_fields)),
                    ]),
                    const SizedBox(height: 16),
                    _FormRow(children: [
                      Expanded(
                        child: _DropdownField<String>(
                          value: _selectedJk,
                          label: 'Jenis Kelamin',
                          icon: Icons.wc_outlined,
                          items: const [
                            DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                            DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                          ],
                          onChanged: (v) => _selectedJk = v,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DropdownField<String>(
                          value: _selectedStatusGuru,
                          label: 'Status',
                          icon: Icons.flag_outlined,
                          items: const [
                            DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                            DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
                          ],
                          onChanged: (v) => _selectedStatusGuru = v,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Jabatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      ...['Guru Mapel', 'Wali Kelas', 'Kepala Madrasah', 'Wakil Kurikulum', 'Guru BK'].map((j) {
                        final val = j == 'Guru Mapel' ? 'guru_mapel' : j == 'Wali Kelas' ? 'wali_kelas' : j == 'Kepala Madrasah' ? 'kepala_sekolah' : j == 'Wakil Kurikulum' ? 'wakil_kurikulum' : 'guru_bk';
                        return CheckboxListTile(
                          dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                          title: Text(j, style: const TextStyle(fontSize: 14)),
                          value: _selectedJabatanSet.contains(val),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) _selectedJabatanSet.add(val);
                              else _selectedJabatanSet.remove(val);
                            });
                          },
                        );
                      }),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  _FormCard(title: 'Akun Login', icon: Icons.lock_outline, children: [
                    _FormRow(children: [
                      Expanded(child: _ModernField(controller: _guruUsernameCtrl, label: 'Username', icon: Icons.person_outline)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _guruPasswordCtrl,
                          obscureText: true,
                          decoration: _inputDecoration('Password', Icons.lock_outline),
                        ),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  _FormCard(title: 'Mata Pelajaran yang Diampu', icon: Icons.book_outlined, children: [
                    if (mapelList.isEmpty)
                      const Text('Memuat data mapel...', style: TextStyle(color: Colors.grey))
                    else
                      ...mapelList.map((m) => CheckboxListTile(
                        dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                        title: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                        value: _selectedGuruMapelIds.contains(m['id'] as int),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) _selectedGuruMapelIds.add(m['id'] as int);
                            else _selectedGuruMapelIds.remove(m['id'] as int);
                          });
                        },
                      )),
                  ]),
                  const SizedBox(height: 16),
                  _FormCard(title: 'Kelas yang Diajar', icon: Icons.meeting_room_outlined, children: [
                    if (kelasList.isEmpty)
                      const Text('Memuat data kelas...', style: TextStyle(color: Colors.grey))
                    else
                      ...kelasList.map((k) => CheckboxListTile(
                        dense: true, contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                        title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                        value: _selectedGuruKelasIds.contains(k['id'] as int),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) _selectedGuruKelasIds.add(k['id'] as int);
                            else _selectedGuruKelasIds.remove(k['id'] as int);
                          });
                        },
                      )),
                  ]),
                ])
              else if (idx == 10)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _FormCard(title: 'Data Ruangan', icon: Icons.room_outlined, children: [
                    _ModernField(controller: ctrls['nama']!, label: 'Nama Ruangan', icon: Icons.badge_outlined, hint: 'Contoh: Aula, Lab. Komputer, Kelas 1A'),
                    const SizedBox(height: 16),
                    _ModernField(controller: ctrls['kapasitas']!, label: 'Kapasitas', icon: Icons.people_outlined, hint: 'Jumlah maksimal orang'),
                  ]),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final body = <String, dynamic>{};
              for (final col in cfg.columns) {
                if ((idx == 0 || idx == 1) && col == 'is_aktif') {
                  body[col] = _selectedAktif == 'Aktif' ? 1 : 0;
                } else if ((idx == 1 || idx == 4) && col == 'tahun_ajaran_id') {
                  body[col] = _selectedTaId;
                } else if (idx == 1 && col == 'nama') {
                  body[col] = _selectedNamaSemester;
                } else if (idx == 4 && col == 'tingkat_id') {
                  body[col] = _selectedTingkatId;
                } else if (idx == 4 && col == 'jurusan_id') {
                  body[col] = _selectedJurusanId;
                } else if (idx == 6 && col == 'jenis_kelamin') {
                  body[col] = _selectedJk;
                } else if (idx == 6 && col == 'jabatan') {
                  body[col] = _selectedJabatanSet.join(',');
                } else if (idx == 6 && col == 'status_aktif') {
                  body[col] = _selectedStatusGuru == 'Aktif' ? 1 : 0;
                } else if (idx == 9 && col == 'jenis_kelamin') {
                  body[col] = _selectedSiswaJk;
                } else if (idx == 9 && col == 'kelas_id') {
                  body[col] = _selectedSiswaKelasId;
                } else if (idx == 9 && col == 'status') {
                  body[col] = _selectedSiswaStatus;
                } else {
                  body[col] = ctrls[col]!.text;
                }
              }
              if (idx == 6) {
                body['username'] = _guruUsernameCtrl.text;
                body['password'] = _guruPasswordCtrl.text;
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
                    'kelas_ids': _selectedKelasIds.toList(),
                  });
                }
                if (idx == 6 && savedId != null) {
                  await ApiClient.put('/admin/guru-mapel/$savedId/mapel', body: {
                    'mapel_ids': _selectedGuruMapelIds.toList(),
                  });
                  await ApiClient.put('/admin/guru-kelas/$savedId/kelas', body: {
                    'kelas_ids': _selectedGuruKelasIds.toList(),
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
    final ok = await showConfirmDialog(context, title: 'Hapus', message: 'Yakin hapus ${_tabs[idx].label} ini?');
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
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NIS: ${r['nis']}  |  ${r['nama']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'JK: ${r['jenis_kelamin']}  |  Kelas: ${r['kelas_nama']}  |  Status: ${r['status']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: Colors.red),
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
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                    ));
                  }
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
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nama: ${r['nama']}  |  Kode: ${r['kode'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: Colors.red),
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
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                    ));
                  }
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
        title: Text('Preview Data Guru (${rows.length} baris)'),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rows.where((r) => r['valid'] == true).length} valid, ${rows.where((r) => r['valid'] != true).length} error',
                  style: TextStyle(color: rows.any((r) => r['valid'] != true) ? Colors.red : Colors.green, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: r['valid'] == true ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r['valid'] == true ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r['row']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NIP: ${r['nip']}  |  ${r['nama']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          'JK: ${r['jenis_kelamin']}  |  Jabatan: ${r['jabatan']}  |  Status: ${r['status_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        Text(
                          'Username: ${r['username']}  |  Password: ${r['password'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        if (r['errors'] is List && (r['errors'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (r['errors'] as List).join('; '),
                              style: const TextStyle(fontSize: 12, color: Colors.red),
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
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Berhasil: $inserted ditambahkan${errors.isNotEmpty ? ', ${errors.length} gagal' : ''}'),
                    ));
                  }
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
          decoration: BoxDecoration(color: Colors.grey[50], border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Menu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500])),
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
                    color: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(t.icon, size: 20, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey[600]),
                    title: Text(t.label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : null, color: isActive ? null : Colors.grey[700])),
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
            if (totalData > 0) Text('$totalData data', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
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
    if (_error[idx] != null) return Center(child: Text(_error[idx]!, style: const TextStyle(color: Colors.red)));
    if (_data[idx]!.isEmpty) return Center(child: Text('Belum ada data.', style: TextStyle(color: Colors.grey[500])));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: cfg.displayCols.map((h) => Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            )).toList()),
          ),
        ),
        Expanded(child: ListView.separated(
          itemCount: _data[idx]!.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final row = _data[idx]![i];
            return Container(
              color: i.isEven ? null : Colors.grey[50],
              child: ListTile(
                dense: true,
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: cfg.columns.asMap().entries.map((e) {
                    final col = cfg.columns[e.key];
                    final val = _displayValue(col, row[col], idx: idx, row: row);
                    return Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(val, style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis)),
                    );
                  }).toList()),
                ),
                trailing: (idx == 7 || idx == 8) ? null : Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey), onPressed: () => _showForm(idx, edit: row)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _delete(idx, row['id'] as int)),
                ]),
              ),
            );
          },
        )),
        if (_totalPages[idx]! > 1) Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            border: Border(top: BorderSide(color: Colors.grey[200]!))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _page[idx]! > 1 ? () {
              _page[idx] = _page[idx]! - 1;
              _load(idx);
            } : null),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
              child: Text('${_page[idx]} / ${_totalPages[idx]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: _page[idx]! < _totalPages[idx]! ? () {
              _page[idx] = _page[idx]! + 1;
              _load(idx);
            } : null),
          ]),
        ),
      ]),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _FormCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
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
  const _ModernField({required this.controller, required this.label, required this.icon, this.hint, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        suffixText: optional ? 'Opsional' : null,
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
      ),
    );
  }
}

InputDecoration _searchDeco() {
  return InputDecoration(
    hintText: 'Cari...',
    prefixIcon: const Icon(Icons.search, size: 20),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
  );
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
  );
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
        fillColor: const Color(0xFFF8FAFC),
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
