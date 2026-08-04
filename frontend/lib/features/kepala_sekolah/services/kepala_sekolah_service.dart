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

  static Future<Map<String, dynamic>> getAbsensi({String? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/kepala-sekolah/absensi', queryParams: params);
    return res;
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
}
