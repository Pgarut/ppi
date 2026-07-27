import '../../../core/network/api_client.dart';

class GuruBKService {
  static Future<Map<String, dynamic>> getPengaduan({int page = 1, int perPage = 20, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (status != null) params['status'] = status;
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

  static Future<void> createJadwalKonseling(Map<String, dynamic> body) async {
    await ApiClient.post('/guru-bk/jadwal-konseling', body: body);
  }

  static Future<void> updateJadwalKonseling(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru-bk/jadwal-konseling/$id', body: body);
  }

  static Future<void> deleteJadwalKonseling(int id) async {
    await ApiClient.delete('/guru-bk/jadwal-konseling/$id');
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

  // ── Bakat & Minat ──

  static Future<List<dynamic>> getBakatMinat({String? jenis}) async {
    final params = <String, String>{};
    if (jenis != null) params['jenis'] = jenis;
    final res = await ApiClient.get('/guru-bk/bakat-minat', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  static Future<void> createBakatMinat(Map<String, dynamic> body) async {
    await ApiClient.post('/guru-bk/bakat-minat', body: body);
  }

  static Future<void> updateBakatMinat(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru-bk/bakat-minat/$id', body: body);
  }

  static Future<void> deleteBakatMinat(int id) async {
    await ApiClient.delete('/guru-bk/bakat-minat/$id');
  }

  // ── Monitoring Akademik ──

  static Future<List<dynamic>> getMonitoringNilai({int? siswaId, int? kelasId}) async {
    final params = <String, String>{};
    if (siswaId != null) params['siswa_id'] = '$siswaId';
    if (kelasId != null) params['kelas_id'] = '$kelasId';
    final res = await ApiClient.get('/guru-bk/monitoring/nilai', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getMonitoringAbsensi({int? siswaId, int? kelasId}) async {
    final params = <String, String>{};
    if (siswaId != null) params['siswa_id'] = '$siswaId';
    if (kelasId != null) params['kelas_id'] = '$kelasId';
    final res = await ApiClient.get('/guru-bk/monitoring/absensi', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getMonitoringPelanggaran() async {
    final res = await ApiClient.get('/guru-bk/monitoring/pelanggaran');
    return res['data'] as List<dynamic>;
  }

  // ── Referensi ──

  static Future<List<dynamic>> getSiswaList() async {
    final res = await ApiClient.get('/siswa');
    return res['data'] as List<dynamic>? ?? [];
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

  static Future<List<dynamic>> getLaporanMonitoring() async {
    final res = await ApiClient.get('/guru-bk/laporan/monitoring');
    return res['data'] as List<dynamic>;
  }
}
