class Siswa {
  final int id;
  final String nis;
  final String? nisn;
  final String nama;
  final String? jenisKelamin;
  final int? kelasId;
  final String? kelasNama;
  final String? status;

  const Siswa({
    required this.id,
    required this.nis,
    this.nisn,
    required this.nama,
    this.jenisKelamin,
    this.kelasId,
    this.kelasNama,
    this.status,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      id: json['id'] as int,
      nis: json['nis'] as String? ?? '',
      nisn: json['nisn'] as String?,
      nama: json['nama'] as String? ?? '',
      jenisKelamin: json['jenis_kelamin'] as String?,
      kelasId: json['kelas_id'] as int?,
      kelasNama: json['kelas_nama'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nis': nis,
      'nisn': nisn,
      'nama': nama,
      'jenis_kelamin': jenisKelamin,
      'kelas_id': kelasId,
      'kelas_nama': kelasNama,
      'status': status,
    };
  }

  bool get isAktif => status == 'Aktif';
}
