class Nilai {
  final int? id;
  final String? siswaNama;
  final String? mapelNama;
  final String? kelasNama;
  final String? semesterNama;
  final String? jenis;
  final dynamic nilai;
  final String? statusValidasi;

  const Nilai({
    this.id,
    this.siswaNama,
    this.mapelNama,
    this.kelasNama,
    this.semesterNama,
    this.jenis,
    this.nilai,
    this.statusValidasi,
  });

  factory Nilai.fromJson(Map<String, dynamic> json) {
    return Nilai(
      id: json['id'] as int?,
      siswaNama: json['siswa_nama'] as String?,
      mapelNama: json['mapel_nama'] as String?,
      kelasNama: json['kelas_nama'] as String?,
      semesterNama: json['semester_nama'] as String?,
      jenis: json['jenis'] as String?,
      nilai: json['nilai'],
      statusValidasi: json['status_validasi'] as String?,
    );
  }

  num? get nilaiNum {
    if (nilai is num) return nilai as num;
    if (nilai is String) return num.tryParse(nilai);
    return null;
  }

  bool get isDraft => statusValidasi == 'draft';
  bool get isValidated => statusValidasi == 'tervalidasi' || statusValidasi == 'divalidasi';
}

class BobotNilai {
  final int? id;
  final String? mapelNama;
  final int? mataPelajaranId;
  final int tahunAjaranId;
  final num harianPersen;
  final num tugasPersen;
  final num utsPersen;
  final num uasPersen;

  const BobotNilai({
    this.id,
    this.mapelNama,
    this.mataPelajaranId,
    required this.tahunAjaranId,
    required this.harianPersen,
    required this.tugasPersen,
    required this.utsPersen,
    required this.uasPersen,
  });

  factory BobotNilai.fromJson(Map<String, dynamic> json) {
    return BobotNilai(
      id: json['id'] as int?,
      mapelNama: json['mapel_nama'] as String?,
      mataPelajaranId: json['mata_pelajaran_id'] as int?,
      tahunAjaranId: json['tahun_ajaran_id'] as int,
      harianPersen: json['harian_persen'] ?? 0,
      tugasPersen: json['tugas_persen'] ?? 0,
      utsPersen: json['uts_persen'] ?? 0,
      uasPersen: json['uas_persen'] ?? 0,
    );
  }

  bool get isDefault => mataPelajaranId == null;
  String get displayName => isDefault ? 'Default' : (mapelNama ?? '-');
}
