class GuruMapelKelas {
  final int? id;
  final int guruId;
  final int mataPelajaranId;
  final int kelasId;
  final String? mapelNama;
  final String? kelasNama;

  const GuruMapelKelas({
    this.id,
    required this.guruId,
    required this.mataPelajaranId,
    required this.kelasId,
    this.mapelNama,
    this.kelasNama,
  });

  factory GuruMapelKelas.fromJson(Map<String, dynamic> json) {
    return GuruMapelKelas(
      id: json['id'] as int?,
      guruId: json['guru_id'] as int,
      mataPelajaranId: json['mata_pelajaran_id'] as int,
      kelasId: json['kelas_id'] as int,
      mapelNama: json['mapel_nama'] as String?,
      kelasNama: json['kelas_nama'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mata_pelajaran_id': mataPelajaranId,
      'kelas_id': kelasId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuruMapelKelas &&
        other.guruId == guruId &&
        other.mataPelajaranId == mataPelajaranId &&
        other.kelasId == kelasId;
  }

  @override
  int get hashCode => Object.hash(guruId, mataPelajaranId, kelasId);
}
