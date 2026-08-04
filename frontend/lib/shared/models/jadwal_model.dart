class Jadwal {
  final int? id;
  final String hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? mapelNama;
  final String? guruNama;
  final String? kelasNama;
  final String? ruanganNama;
  final int? jpKe;
  final int? mataPelajaranId;
  final int? guruId;
  final int? kelasId;
  final int? ruanganId;
  final int? semesterId;
  final String? status;

  const Jadwal({
    this.id,
    required this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.mapelNama,
    this.guruNama,
    this.kelasNama,
    this.ruanganNama,
    this.jpKe,
    this.mataPelajaranId,
    this.guruId,
    this.kelasId,
    this.ruanganId,
    this.semesterId,
    this.status,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'] as int?,
      hari: json['hari'] as String? ?? '',
      jamMulai: json['jam_mulai'] as String?,
      jamSelesai: json['jam_selesai'] as String?,
      mapelNama: json['mapel_nama'] as String? ?? json['mapel'] as String?,
      guruNama: json['guru_nama'] as String? ?? json['guru'] as String?,
      kelasNama: json['kelas_nama'] as String? ?? json['kelas'] as String?,
      ruanganNama: json['ruangan_nama'] as String? ?? json['ruangan'] as String?,
      jpKe: json['jp_ke'] as int?,
      mataPelajaranId: json['mata_pelajaran_id'] as int?,
      guruId: json['guru_id'] as int?,
      kelasId: json['kelas_id'] as int?,
      ruanganId: json['ruangan_id'] as int?,
      semesterId: json['semester_id'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'mata_pelajaran_id': mataPelajaranId,
      'guru_id': guruId,
      'kelas_id': kelasId,
      'ruangan_id': ruanganId,
      'semester_id': semesterId,
      'jp_ke': jpKe,
    };
  }
}
