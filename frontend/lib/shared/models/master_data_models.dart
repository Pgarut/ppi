class Kelas {
  final int id;
  final String nama;
  final int? tingkatId;
  final int? jurusanId;
  final int? tahunAjaranId;

  const Kelas({
    required this.id,
    required this.nama,
    this.tingkatId,
    this.jurusanId,
    this.tahunAjaranId,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json['id'] as int,
      nama: json['nama'] as String? ?? '',
      tingkatId: json['tingkat_id'] as int?,
      jurusanId: json['jurusan_id'] as int?,
      tahunAjaranId: json['tahun_ajaran_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'tingkat_id': tingkatId,
      'jurusan_id': jurusanId,
      'tahun_ajaran_id': tahunAjaranId,
    };
  }
}

class MataPelajaran {
  final int id;
  final String nama;
  final String? kode;

  const MataPelajaran({required this.id, required this.nama, this.kode});

  factory MataPelajaran.fromJson(Map<String, dynamic> json) {
    return MataPelajaran(
      id: json['id'] as int,
      nama: json['nama'] as String? ?? '',
      kode: json['kode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'kode': kode};
}

class TahunAjaran {
  final int id;
  final String nama;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final int? isAktif;

  const TahunAjaran({
    required this.id,
    required this.nama,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.isAktif,
  });

  factory TahunAjaran.fromJson(Map<String, dynamic> json) {
    return TahunAjaran(
      id: json['id'] as int,
      nama: json['nama'] as String? ?? '',
      tanggalMulai: json['tanggal_mulai'] as String?,
      tanggalSelesai: json['tanggal_selesai'] as String?,
      isAktif: json['is_aktif'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'tanggal_mulai': tanggalMulai,
      'tanggal_selesai': tanggalSelesai,
      'is_aktif': isAktif,
    };
  }

  bool get isActive => isAktif == 1;
}

class Semester {
  final int id;
  final String nama;
  final int tahunAjaranId;
  final int? isAktif;

  const Semester({
    required this.id,
    required this.nama,
    required this.tahunAjaranId,
    this.isAktif,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as int,
      nama: json['nama'] as String? ?? '',
      tahunAjaranId: json['tahun_ajaran_id'] as int,
      isAktif: json['is_aktif'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'tahun_ajaran_id': tahunAjaranId, 'is_aktif': isAktif};
  }

  bool get isActive => isAktif == 1;
}

class Jurusan {
  final int id;
  final String nama;
  final String? kode;

  const Jurusan({required this.id, required this.nama, this.kode});

  factory Jurusan.fromJson(Map<String, dynamic> json) {
    return Jurusan(id: json['id'] as int, nama: json['nama'] as String? ?? '', kode: json['kode'] as String?);
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'kode': kode};
}

class Tingkat {
  final int id;
  final String nama;
  final String? jenjang;

  const Tingkat({required this.id, required this.nama, this.jenjang});

  factory Tingkat.fromJson(Map<String, dynamic> json) {
    return Tingkat(id: json['id'] as int, nama: json['nama'] as String? ?? '', jenjang: json['jenjang'] as String?);
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'jenjang': jenjang};
}

class Ruangan {
  final int id;
  final String nama;
  final String? kapasitas;

  const Ruangan({required this.id, required this.nama, this.kapasitas});

  factory Ruangan.fromJson(Map<String, dynamic> json) {
    return Ruangan(id: json['id'] as int, nama: json['nama'] as String? ?? '', kapasitas: json['kapasitas'] as String?);
  }

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'kapasitas': kapasitas};
}
