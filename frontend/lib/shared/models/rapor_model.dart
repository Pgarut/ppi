class Rapor {
  final int? id;
  final String? siswaNama;
  final String? siswaNis;
  final String? mapelNama;
  final String? kelasNama;
  final String? semesterNama;
  final String? predikat;
  final dynamic nilaiAkhir;
  final String? statusKirim;
  final String? dicetakPada;
  final String? catatanWaliKelas;

  const Rapor({
    this.id,
    this.siswaNama,
    this.siswaNis,
    this.mapelNama,
    this.kelasNama,
    this.semesterNama,
    this.predikat,
    this.nilaiAkhir,
    this.statusKirim,
    this.dicetakPada,
    this.catatanWaliKelas,
  });

  factory Rapor.fromJson(Map<String, dynamic> json) {
    return Rapor(
      id: json['id'] as int?,
      siswaNama: json['siswa_nama'] as String?,
      siswaNis: json['siswa_nis'] as String?,
      mapelNama: json['mapel_nama'] as String?,
      kelasNama: json['kelas_nama'] as String?,
      semesterNama: json['semester_nama'] as String?,
      predikat: json['predikat'] as String?,
      nilaiAkhir: json['nilai_akhir'],
      statusKirim: json['status_kirim'] as String?,
      dicetakPada: json['dicetak_pada'] as String?,
      catatanWaliKelas: json['catatan_wali_kelas'] as String?,
    );
  }

  num? get nilaiAkhirNum {
    if (nilaiAkhir is num) return nilaiAkhir as num;
    if (nilaiAkhir is String) return num.tryParse(nilaiAkhir);
    return null;
  }

  bool get isDraft => statusKirim == 'draft';
  bool get isSent => statusKirim == 'terkirim';
  bool get isValidated => statusKirim == 'divalidasi';
}
