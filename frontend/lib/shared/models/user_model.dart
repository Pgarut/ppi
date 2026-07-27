class UserModel {
  final int id;
  final String username;
  final String role;
  final int? guruId;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.guruId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      guruId: json['guru_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'guru_id': guruId,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isKepalaSekolah => role == 'kepala_sekolah';
  bool get isWakilKurikulum => role == 'wakil_kurikulum';
  bool get isGuru => role == 'guru_mapel_wali_kelas';
  bool get isGuruBk => role == 'guru_bk';

  static String roleDisplayName(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'kepala_sekolah': return 'Kepala Madrasah (Kamad)';
      case 'wakil_kurikulum': return 'Wakil Kurikulum';
      case 'guru_mapel_wali_kelas': return 'Guru Mapel / Wali Kelas';
      case 'guru_bk': return 'Guru BK';
      default: return role;
    }
  }
}
