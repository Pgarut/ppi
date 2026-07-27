import '../../../core/network/api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/admin/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> list(String resource, {int page = 1, int perPage = 20, String? search, Map<String, String>? filters}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (filters != null) params.addAll(filters);
    final res = await ApiClient.get('/admin/$resource', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getById(String resource, int id) async {
    final res = await ApiClient.get('/admin/$resource/$id');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create(String resource, Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/$resource', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> update(String resource, int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/$resource/$id', body: body);
  }

  static Future<void> delete(String resource, int id) async {
    await ApiClient.delete('/admin/$resource/$id');
  }

  static Future<Map<String, dynamic>> getUsers({int page = 1, int perPage = 20, String? search}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/admin/users', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/admin/users', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateUser(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/admin/users/$id', body: body);
  }

  static Future<void> deleteUser(int id) async {
    await ApiClient.delete('/admin/users/$id');
  }

  static Future<List<dynamic>> getHakAkses() async {
    final res = await ApiClient.get('/admin/hak-akses');
    return res['data'] as List<dynamic>;
  }

  static Future<void> addHakAkses(Map<String, dynamic> body) async {
    await ApiClient.post('/admin/hak-akses', body: body);
  }

  static Future<void> deleteHakAkses(int id) async {
    await ApiClient.delete('/admin/hak-akses/$id');
  }

  static Future<void> backup() async {
    await ApiClient.post('/admin/backup');
  }

  static Future<void> restore(Map<String, dynamic> body) async {
    await ApiClient.post('/admin/restore', body: body);
  }

  static Future<Map<String, dynamic>> getLogAktivitas({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/log-aktivitas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Absensi ──
  static Future<Map<String, dynamic>> getAbsensiGuru({int page = 1, int perPage = 20, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/absensi/guru', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAbsensiSiswa({int page = 1, int perPage = 20, String? kelasId, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/admin/absensi/siswa', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRekapAbsensi({String? tanggalMulai, String? tanggalSelesai, String? kelasId}) async {
    final params = <String, String>{};
    if (tanggalMulai != null) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalSelesai != null) params['tanggal_selesai'] = tanggalSelesai;
    if (kelasId != null) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/admin/absensi/rekap', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Nilai ──
  static Future<Map<String, dynamic>> getNilai({int page = 1, int perPage = 20, String? kelasId, String? mapelId, String? jenis, String? statusValidasi, String? semesterId}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (mapelId != null) params['mata_pelajaran_id'] = mapelId;
    if (jenis != null) params['jenis'] = jenis;
    if (statusValidasi != null) params['status_validasi'] = statusValidasi;
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/admin/nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> validasiNilai(int id) async {
    await ApiClient.put('/admin/nilai/$id/validasi');
  }

  // ── Rapor ──
  static Future<Map<String, dynamic>> getRapor({int page = 1, int perPage = 20, String? kelasId, String? semesterId, String? statusKirim}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (semesterId != null) params['semester_id'] = semesterId;
    if (statusKirim != null) params['status_kirim'] = statusKirim;
    final res = await ApiClient.get('/admin/rapor', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> cetakRapor(int id) async {
    await ApiClient.post('/admin/rapor/$id/cetak');
  }

  static Future<Map<String, dynamic>> getArsipRapor({int page = 1, int perPage = 20}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    final res = await ApiClient.get('/admin/rapor/arsip', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Pengaturan Tampilan Login ──
  static Future<List<dynamic>> getPengaturanTampilan() async {
    final res = await ApiClient.get('/admin/pengaturan-tampilan');
    return res['data'] as List<dynamic>;
  }

  static Future<void> updatePengaturanTampilan(Map<String, String> body) async {
    await ApiClient.put('/admin/pengaturan-tampilan', body: body);
  }
}
