import '../../../core/network/api_client.dart';

class GuruBKService {
  static Future<Map<String, dynamic>> getPengaduan({int page = 1, int perPage = 20, String? status, String? kategori}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (status != null) params['status'] = status;
    if (kategori != null) params['kategori'] = kategori;
    final res = await ApiClient.get('/guru-bk/pengaduan', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updatePengaduan(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru-bk/pengaduan/$id', body: body);
  }

  static Future<Map<String, dynamic>> getStatistik() async {
    final res = await ApiClient.get('/guru-bk/statistik');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getLaporanBulanan({String? tahun, String? bulan}) async {
    final params = <String, String>{};
    if (tahun != null) params['tahun'] = tahun;
    if (bulan != null) params['bulan'] = bulan;
    final res = await ApiClient.get('/guru-bk/bulanan', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getRekapKasus() async {
    final res = await ApiClient.get('/guru-bk/rekap-kasus');
    return res['data'] as List<dynamic>;
  }

  // ── Konseling / Jadwal ──

  static Future<Map<String, dynamic>> getJadwalKonseling({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/guru-bk/jadwal-konseling', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createJadwalKonseling(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru-bk/jadwal-konseling', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateJadwalKonseling(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru-bk/jadwal-konseling/$id', body: body);
  }

  static Future<void> deleteJadwalKonseling(int id) async {
    await ApiClient.delete('/guru-bk/jadwal-konseling/$id');
  }

  /// History jadwal + catatan (digabung)
  static Future<Map<String, dynamic>> getHistoryKonseling({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/guru-bk/jadwal-konseling/history', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKonseling({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/guru-bk/konseling', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKonselingById(int id) async {
    final res = await ApiClient.get('/guru-bk/konseling/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> createKonseling(Map<String, dynamic> body) async {
    await ApiClient.post('/guru-bk/konseling', body: body);
  }

  static Future<void> updateKonseling(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru-bk/konseling/$id', body: body);
  }

  /// Dapatkan daftar kelas utk dropdown
  static Future<List<dynamic>> getKelasList() async {
    final res = await ApiClient.get('/referensi');
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return data['kelas'] as List<dynamic>? ?? [];
  }

  /// Dapatkan daftar siswa + status jadwal per kelas
  static Future<List<dynamic>> getSiswaByKelas(int kelasId) async {
    final res = await ApiClient.get('/guru-bk/jadwal-konseling/siswa', queryParams: {'kelas_id': '$kelasId'});
    return res['data'] as List<dynamic>? ?? [];
  }

  // ── Bakat & Minat ──

  static Future<List<dynamic>> getBakatMinat({String? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/guru-bk/bakat-minat', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  /// Dapatkan siswa per kelas + status bakat-minat
  static Future<List<dynamic>> getSiswaBakatMinat(int kelasId) async {
    final res = await ApiClient.get('/guru-bk/bakat-minat/siswa', queryParams: {'kelas_id': '$kelasId'});
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Simpan data bakat minat (create or update)
  static Future<void> saveBakatMinat(Map<String, dynamic> body) async {
    if (body['id'] != null) {
      await ApiClient.put('/guru-bk/bakat-minat/${body['id']}', body: body);
    } else {
      await ApiClient.post('/guru-bk/bakat-minat', body: body);
    }
  }

  static Future<void> deleteBakatMinat(int id) async {
    await ApiClient.delete('/guru-bk/bakat-minat/$id');
  }

  // ── Monitoring Akademik ──

  /// Monitoring absensi — rekap per santri, filter by kelas_id
  static Future<List<dynamic>> getMonitoringAbsensi({int? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = '$kelasId';
    final res = await ApiClient.get('/guru-bk/monitoring/absensi', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  /// Monitoring pelanggaran — rekap per santri, filter by kelas_id
  static Future<List<dynamic>> getMonitoringPelanggaran({int? kelasId}) async {
    final params = <String, String>{};
    if (kelasId != null) params['kelas_id'] = '$kelasId';
    final res = await ApiClient.get('/guru-bk/monitoring/pelanggaran', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  // ── Laporan ──

  static Future<List<dynamic>> getLaporanKonseling() async {
    final res = await ApiClient.get('/guru-bk/laporan/konseling');
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getLaporanBakatMinat() async {
    final res = await ApiClient.get('/guru-bk/laporan/bakat-minat');
    return res['data'] as List<dynamic>;
  }

  /// Monitoring (nilai, absensi, pengaduan) — return Map
  static Future<Map<String, dynamic>> getLaporanMonitoring() async {
    final res = await ApiClient.get('/guru-bk/laporan/monitoring');
    return res['data'] as Map<String, dynamic>;
  }
}
