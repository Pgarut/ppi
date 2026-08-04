class LogAktivitas {
  final int? id;
  final String? aksi;
  final String? modul;
  final String? detail;
  final String? username;
  final String? createdAt;

  const LogAktivitas({
    this.id,
    this.aksi,
    this.modul,
    this.detail,
    this.username,
    this.createdAt,
  });

  factory LogAktivitas.fromJson(Map<String, dynamic> json) {
    return LogAktivitas(
      id: json['id'] as int?,
      aksi: json['aksi'] as String?,
      modul: json['modul'] as String?,
      detail: json['detail'] as String?,
      username: json['username'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class HakAkses {
  final int id;
  final String role;
  final String modul;
  final String aksi;

  const HakAkses({
    required this.id,
    required this.role,
    required this.modul,
    required this.aksi,
  });

  factory HakAkses.fromJson(Map<String, dynamic> json) {
    return HakAkses(
      id: json['id'] as int,
      role: json['role'] as String? ?? '',
      modul: json['modul'] as String? ?? '',
      aksi: json['aksi'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'role': role, 'modul': modul, 'aksi': aksi};
}

class ProfilSekolah {
  final String? nama;
  final String? alamat;
  final String? telepon;
  final String? email;

  const ProfilSekolah({this.nama, this.alamat, this.telepon, this.email});

  factory ProfilSekolah.fromJson(Map<String, dynamic> json) {
    return ProfilSekolah(
      nama: json['nama'] as String?,
      alamat: json['alamat'] as String?,
      telepon: json['telepon'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'nama': nama, 'alamat': alamat, 'telepon': telepon, 'email': email};
}
