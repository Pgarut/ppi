class Pengaduan {
  final int? id;
  final int siswaId;
  final String? siswaNama;
  final String? kategori;
  final String? deskripsi;
  final String? buktiUrl;
  final String? status;
  final String? tindakLanjut;
  final String? createdAt;

  const Pengaduan({
    this.id,
    required this.siswaId,
    this.siswaNama,
    this.kategori,
    this.deskripsi,
    this.buktiUrl,
    this.status,
    this.tindakLanjut,
    this.createdAt,
  });

  factory Pengaduan.fromJson(Map<String, dynamic> json) {
    return Pengaduan(
      id: json['id'] as int?,
      siswaId: json['siswa_id'] as int,
      siswaNama: json['siswa_nama'] as String?,
      kategori: json['kategori'] as String?,
      deskripsi: json['deskripsi'] as String?,
      buktiUrl: json['bukti_url'] as String?,
      status: json['status'] as String?,
      tindakLanjut: json['tindak_lanjut'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siswa_id': siswaId,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'status': status,
      'tindak_lanjut': tindakLanjut,
    };
  }

  bool get isPending => status == 'diproses';
  bool get isResolved => status == 'selesai';
}

class Konseling {
  final int? id;
  final int? siswaId;
  final String? siswaNama;
  final String? tanggal;
  final String? jam;
  final String? hari;
  final String? jenis;
  final String? catatan;
  final String? status;

  const Konseling({
    this.id,
    this.siswaId,
    this.siswaNama,
    this.tanggal,
    this.jam,
    this.hari,
    this.jenis,
    this.catatan,
    this.status,
  });

  factory Konseling.fromJson(Map<String, dynamic> json) {
    return Konseling(
      id: json['id'] as int?,
      siswaId: json['siswa_id'] as int?,
      siswaNama: json['siswa_nama'] as String?,
      tanggal: json['tanggal'] as String?,
      jam: json['jam'] as String?,
      hari: json['hari'] as String?,
      jenis: json['jenis'] as String?,
      catatan: json['catatan'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siswa_id': siswaId,
      'tanggal': tanggal,
      'jam': jam,
      'jenis': jenis,
      'catatan': catatan,
    };
  }
}

class BakatMinat {
  final int? id;
  final int? siswaId;
  final String? siswaNama;
  final String? nis;
  final String? kelasNama;
  final String? jenis;
  final String? deskripsi;
  final String? catatan;

  const BakatMinat({
    this.id,
    this.siswaId,
    this.siswaNama,
    this.nis,
    this.kelasNama,
    this.jenis,
    this.deskripsi,
    this.catatan,
  });

  factory BakatMinat.fromJson(Map<String, dynamic> json) {
    return BakatMinat(
      id: json['bm_id'] as int? ?? json['id'] as int?,
      siswaId: json['siswa_id'] as int?,
      siswaNama: json['siswa_nama'] as String?,
      nis: json['nis'] as String?,
      kelasNama: json['kelas_nama'] as String?,
      jenis: json['jenis'] as String?,
      deskripsi: json['deskripsi'] as String?,
      catatan: json['catatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siswa_id': siswaId,
      'jenis': jenis,
      'deskripsi': deskripsi,
      'catatan': catatan,
    };
  }

  bool get isBakat => jenis == 'bakat';
  bool get isMinat => jenis == 'minat';
}
