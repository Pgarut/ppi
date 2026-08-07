import '../../../core/network/api_client.dart';

/// Service untuk endpoint Kepala Sekolah.
///
/// Konvensi response:
/// - Endpoint list (jadwal, absensi, nilai, rapor) return full response `{data: {data: [...], meta: {...}}}`.
///   Caller harus extract `['data']` untuk mendapatkan list.
/// - Endpoint detail (dashboard, bk) return `res['data']` langsung.
class KepalaSekolahService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/kepala-sekolah/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getJadwal({String? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/kepala-sekolah/jadwal', queryParams: params);
    return res;
  }

  static Future<Map<String, dynamic>> getAbsensiGuru({int page = 1, int perPage = 20, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/kepala-sekolah/absensi/guru', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAbsensiSiswa({int page = 1, int perPage = 20, String? kelasId, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/kepala-sekolah/absensi/siswa', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getNilai({String? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/kepala-sekolah/nilai', queryParams: params);
    return res;
  }

  static Future<Map<String, dynamic>> getRapor({String? kelasId, String? semesterId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/kepala-sekolah/rapor', queryParams: params);
    return res;
  }

  static Future<Map<String, dynamic>> getBK() async {
    final res = await ApiClient.get('/kepala-sekolah/bk');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getLaporan(String jenis, {String? kelasId, String? semesterId}) async {
    final params = <String, String>{'jenis': jenis};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/kepala-sekolah/laporan', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getReferensi() async {
    final res = await ApiClient.get('/referensi');
    return res['data'] as Map<String, dynamic>;
  }

  // ── Dauroh Monitoring Nilai ──

  static Future<Map<String, dynamic>> getDaurohFilters() async {
    final res = await ApiClient.get('/kepala-sekolah/dauroh/filters');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDaurohNilai({
    int page = 1,
    int perPage = 50,
    String? jenjang,
    String? kelasId,
    String? programId,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (jenjang != null && jenjang.isNotEmpty) params['jenjang'] = jenjang;
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/kepala-sekolah/dauroh/nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }
}
