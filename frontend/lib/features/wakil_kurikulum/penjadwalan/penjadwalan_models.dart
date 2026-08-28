part of 'penjadwalan_page.dart';

// ══════════════════════════════ DATA CLASSES ══════════════════════════════

class _KesiapanRowData {
  final int guruId;
  final String nama;
  final String nip;
  List<String> hariAktif;
  int jpMaxPerHari;
  int jpMaxMinggu;
  final List<Map<String, dynamic>> kelasDiampu;
  final List<Map<String, dynamic>> mapelDiampu;
  final int jpTerisi;

  _KesiapanRowData({
    required this.guruId,
    required this.nama,
    required this.nip,
    required this.hariAktif,
    required this.jpMaxPerHari,
    required this.jpMaxMinggu,
    required this.kelasDiampu,
    required this.mapelDiampu,
    required this.jpTerisi,
  });

  factory _KesiapanRowData.fromJson(Map<String, dynamic> json) {
    List<String> hariAktif = [];
    if (json['hari_aktif'] is String) {
      try {
        final parsed = json['hari_aktif'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          hariAktif = (jsonDecode(parsed) as List).cast<String>();
        }
      } catch (_) {}
    } else if (json['hari_aktif'] is List) {
      hariAktif = (json['hari_aktif'] as List).cast<String>();
    }

    List<Map<String, dynamic>> kelasDiampu = [];
    if (json['kelas_diampu'] is String) {
      try {
        final parsed = json['kelas_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          kelasDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    } else if (json['kelas_diampu'] is List) {
      kelasDiampu = (json['kelas_diampu'] as List).cast<Map<String, dynamic>>();
    }

    List<Map<String, dynamic>> mapelDiampu = [];
    if (json['mapel_diampu'] is String) {
      try {
        final parsed = json['mapel_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          mapelDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) {}
    } else if (json['mapel_diampu'] is List) {
      mapelDiampu = (json['mapel_diampu'] as List).cast<Map<String, dynamic>>();
    }

    return _KesiapanRowData(
      guruId: json['id'] as int,
      nama: json['nama']?.toString() ?? '-',
      nip: json['nip']?.toString() ?? '-',
      hariAktif: hariAktif,
      jpMaxPerHari: json['jp_max_per_hari'] as int? ?? 8,
      jpMaxMinggu: json['jp_max_per_minggu'] as int? ?? 24,
      kelasDiampu: kelasDiampu,
      mapelDiampu: mapelDiampu,
      jpTerisi: json['jp_terisi'] as int? ?? 0,
    );
  }
}

// ══════════════════════════════ SHARED WIDGETS ══════════════════════════════
