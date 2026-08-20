class UserModel {
  final int id;
  final String username;
  final String role;
  final int? guruId;
  final int? siswaId;
  final String? nama;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.guruId,
    this.siswaId,
    this.nama,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      guruId: json['guru_id'] as int?,
      siswaId: json['siswa_id'] as int?,
      nama: json['nama'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'guru_id': guruId,
      'siswa_id': siswaId,
      'nama': nama,
    };
  }

  String get displayName => nama?.isNotEmpty == true ? nama! : username;

  bool get isAdmin => role == 'admin';
  bool get isKepalaSekolah => role == 'kepala_sekolah';
  bool get isWakilKurikulum => role == 'wakil_kurikulum';
  bool get isGuru => role == 'guru_mapel_wali_kelas';
  bool get isGuruBk => role == 'guru_bk';
  bool get isSiswa => role == 'siswa';
  bool get isMusyrifah => role == 'musyrifah';

  static String roleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'kepala_sekolah': return 'Kepala Madrasah (Kamad)';
      case 'wakil_kurikulum': return 'Wakil Kurikulum';
      case 'guru_mapel_wali_kelas': return 'Asatidz Mapel / Wali Kelas';
      case 'guru_bk': return 'Asatidz BK';
      case 'siswa': return 'Santri';
      case 'musyrifah': return 'Musyrifah at-Ta\'wid';
      default: return role;
    }
  }

  static String jabatanGuru({String? jabatan, bool? isWaliKelas}) {
    if (jabatan != null && jabatan.trim().isNotEmpty) {
      final parts = jabatan.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
      final isMapel = parts.contains('guru_mapel');
      final isWali = parts.contains('wali_kelas');
      if (isMapel && isWali) return 'Asatidz Mapel / Wali Kelas';
      if (isWali) return 'Asatidz Wali Kelas';
      return 'Asatidz Mapel';
    }
    return isWaliKelas == true ? 'Asatidz Mapel / Wali Kelas' : 'Asatidz Mapel';
  }
}
