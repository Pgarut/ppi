class AbsensiGuru {
  final String? guruNip;
  final String? guruNama;
  final String? tanggal;
  final String status;
  final String? jamMasuk;
  final String? jamKeluar;
  final String? keterangan;

  const AbsensiGuru({
    this.guruNip,
    this.guruNama,
    this.tanggal,
    required this.status,
    this.jamMasuk,
    this.jamKeluar,
    this.keterangan,
  });

  factory AbsensiGuru.fromJson(Map<String, dynamic> json) {
    return AbsensiGuru(
      guruNip: json['guru_nip'] as String?,
      guruNama: json['guru_nama'] as String?,
      tanggal: json['tanggal'] as String?,
      status: json['status'] as String? ?? 'alpa',
      jamMasuk: json['jam_masuk'] as String?,
      jamKeluar: json['jam_keluar'] as String?,
      keterangan: json['keterangan'] as String?,
    );
  }

  String get displayName => guruNama ?? guruNip ?? '-';
}

class AbsensiSiswa {
  final String? siswaNis;
  final String? siswaNama;
  final String? kelasNama;
  final String? mapelNama;
  final String? tanggal;
  final String status;
  final String? keterangan;

  const AbsensiSiswa({
    this.siswaNis,
    this.siswaNama,
    this.kelasNama,
    this.mapelNama,
    this.tanggal,
    required this.status,
    this.keterangan,
  });

  factory AbsensiSiswa.fromJson(Map<String, dynamic> json) {
    return AbsensiSiswa(
      siswaNis: json['siswa_nis'] as String?,
      siswaNama: json['siswa_nama'] as String?,
      kelasNama: json['kelas_nama'] as String?,
      mapelNama: json['mapel_nama'] as String?,
      tanggal: json['tanggal'] as String?,
      status: json['status'] as String? ?? 'alpa',
      keterangan: json['keterangan'] as String?,
    );
  }

  String get displayName => siswaNama ?? siswaNis ?? '-';
}
