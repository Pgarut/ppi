class Guru {
  final int id;
  final String nip;
  final String nama;
  final String? jenisKelamin;
  final String? jabatan;
  final int? statusAktif;
  final String? username;

  const Guru({
    required this.id,
    required this.nip,
    required this.nama,
    this.jenisKelamin,
    this.jabatan,
    this.statusAktif,
    this.username,
  });

  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      id: json['id'] as int,
      nip: json['nip'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      jenisKelamin: json['jenis_kelamin'] as String?,
      jabatan: json['jabatan'] as String?,
      statusAktif: json['status_aktif'] as int?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nip': nip,
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'jabatan': jabatan,
      'status_aktif': statusAktif,
      'username': username,
    };
  }

  bool get isAktif => statusAktif == 1;
  String get displayName => nama.isNotEmpty ? nama : nip;
}
