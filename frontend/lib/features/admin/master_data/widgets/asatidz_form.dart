import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/admin/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'form_fields.dart';

class AsatidzForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const AsatidzForm({super.key, this.editData, required this.onSaved});

  @override
  State<AsatidzForm> createState() => _AsatidzFormState();
}

class _AsatidzFormState extends State<AsatidzForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nipCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _selectedJk;
  String? _selectedStatus;
  Set<String> _selectedJabatan = {};
  Set<int> _selectedMapelIds = {};
  Set<int> _selectedKelasIds = {};

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoadingData = false;

  bool get isEditing => widget.editData != null;

  static const _jabatanOptions = [
    MapEntry('guru_mapel', 'Asatidz Mapel'),
    MapEntry('wali_kelas', 'Wali Kelas'),
    MapEntry('kepala_sekolah', 'Kepala Madrasah'),
    MapEntry('wakil_kurikulum', 'Wakil Kurikulum'),
    MapEntry('guru_bk', 'Asatidz BK'),
  ];

  @override
  void initState() {
    super.initState();
    _nipCtrl = TextEditingController(text: widget.editData?['nip']?.toString() ?? '');
    _namaCtrl = TextEditingController(text: widget.editData?['nama']?.toString() ?? '');
    _usernameCtrl = TextEditingController(text: widget.editData?['_username']?.toString() ?? '');
    _passwordCtrl = TextEditingController(text: widget.editData?['_password']?.toString() ?? '');

    if (isEditing) {
      _selectedJk = widget.editData!['jenis_kelamin']?.toString();
      final statusVal = widget.editData!['status_aktif'];
      _selectedStatus = statusVal == 1 ? 'Aktif' : (statusVal == 0 ? 'Tidak Aktif' : null);
      final jabatanStr = widget.editData!['jabatan']?.toString() ?? '';
      if (jabatanStr.isNotEmpty) {
        _selectedJabatan = jabatanStr.split(',').map((s) => s.trim()).toSet();
      }
    }

    _loadData();
  }

  @override
  void dispose() {
    _nipCtrl.dispose();
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final kelasRes = await AdminService.list('kelas', page: 1, perPage: 100);
      _kelasList = (kelasRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _kelasList = [];
    }
    try {
      final mapelRes = await AdminService.list('mata-pelajaran', page: 1, perPage: 100);
      _mapelList = (mapelRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _mapelList = [];
    }
    if (isEditing) {
      await _loadExistingAssignments();
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _loadExistingAssignments() async {
    final gid = widget.editData!['id'] as int;
    try {
      final r = await ApiClient.get('/admin/guru-mapel/$gid/mapel');
      _selectedMapelIds = (r['data'] as List).cast<int>().toSet();
    } catch (_) {}
    try {
      final r = await ApiClient.get('/admin/guru-kelas/$gid/kelas');
      _selectedKelasIds = (r['data'] as List).cast<int>().toSet();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Asatidz' : 'Tambah Asatidz'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDataAsatidzCard(),
              const SizedBox(height: 16),
              _buildAkunLoginCard(),
              const SizedBox(height: 16),
              _buildMapelCard(),
              const SizedBox(height: 16),
              _buildKelasCard(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _onSave, child: const Text('Simpan')),
      ],
    );
  }

  Widget _buildDataAsatidzCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.people_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Data Asatidz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FormRow(children: [
          Expanded(child: ModernField(controller: _nipCtrl, label: 'NIP', icon: Icons.badge_outlined)),
          const SizedBox(width: 16),
          Expanded(child: ModernField(controller: _namaCtrl, label: 'Nama Asatidz', icon: Icons.text_fields)),
        ]),
        const SizedBox(height: 16),
        FormRow(children: [
          Expanded(
            child: ModernDropdown<String>(
              value: _selectedJk,
              label: 'Jenis Kelamin',
              icon: Icons.wc_outlined,
              items: const [
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
              ],
              onChanged: (v) => setState(() => _selectedJk = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ModernDropdown<String>(
              value: _selectedStatus,
              label: 'Status',
              icon: Icons.flag_outlined,
              items: const [
                DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        ModernCheckboxGroup(
          title: 'Jabatan',
          icon: Icons.work_outline,
          options: _jabatanOptions,
          selectedValues: _selectedJabatan,
          onChanged: (val) {
            setState(() {
              if (_selectedJabatan.contains(val)) {
                _selectedJabatan.remove(val);
              } else {
                _selectedJabatan.add(val);
              }
            });
          },
        ),
      ]),
    );
  }

  Widget _buildAkunLoginCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.lock_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Akun Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: FormRow(children: [
        Expanded(child: ModernField(controller: _usernameCtrl, label: 'Username', icon: Icons.person_outline)),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMapelCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.book_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Mata Pelajaran yang Diampu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (_isLoadingData)
          const Text('Memuat data mapel...', style: TextStyle(color: AppTheme.grey500))
        else
          ..._mapelList.map((m) => CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
            value: _selectedMapelIds.contains(m['id'] as int),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedMapelIds.add(m['id'] as int);
                } else {
                  _selectedMapelIds.remove(m['id'] as int);
                }
              });
            },
          )),
      ]),
    );
  }

  Widget _buildKelasCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Kelas yang Diajar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (_isLoadingData)
          const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
        else
          ..._kelasList.map((k) => CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
            value: _selectedKelasIds.contains(k['id'] as int),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedKelasIds.add(k['id'] as int);
                } else {
                  _selectedKelasIds.remove(k['id'] as int);
                }
              });
            },
          )),
      ]),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{
      'nip': _nipCtrl.text,
      'nama': _namaCtrl.text,
      'jenis_kelamin': _selectedJk,
      'jabatan': _selectedJabatan.join(','),
      'status_aktif': _selectedStatus == 'Aktif' ? 1 : 0,
      'username': _usernameCtrl.text,
      'password': _passwordCtrl.text,
    };

    try {
      int? savedId;
      if (isEditing) {
        await AdminService.update('guru', widget.editData!['id'] as int, body);
        savedId = widget.editData!['id'] as int;
      } else {
        final result = await AdminService.create('guru', body);
        savedId = result['id'] as int?;
      }

      if (savedId != null) {
        await ApiClient.put('/admin/guru-mapel/$savedId/mapel', body: {
          'mapel_ids': _selectedMapelIds.toList(),
        });
        await ApiClient.put('/admin/guru-kelas/$savedId/kelas', body: {
          'kelas_ids': _selectedKelasIds.toList(),
        });
      }

      if (context.mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}
