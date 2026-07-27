import '../../../core/network/api_client.dart';

class GuruService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/guru/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAbsensi({int page = 1, int perPage = 50}) async {
    final res = await ApiClient.get('/guru/absensi', queryParams: {'page': '$page', 'per_page': '$perPage'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> inputAbsensiMassal(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/absensi', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSiswaPerKelasAbsensi(String kelasId, {String? tanggal, String? mataPelajaranId}) async {
    final params = <String, String>{'kelas_id': kelasId};
    if (tanggal != null) params['tanggal'] = tanggal;
    if (mataPelajaranId != null) params['mata_pelajaran_id'] = mataPelajaranId;
    final res = await ApiClient.get('/guru/absensi/siswa-per-kelas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getNilai({int page = 1, int perPage = 50}) async {
    final res = await ApiClient.get('/guru/nilai', queryParams: {'page': '$page', 'per_page': '$perPage'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createNilai(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/nilai', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateNilai(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/guru/nilai/$id', body: body);
  }

  static Future<Map<String, dynamic>> getSiswaPerKelasNilai(String kelasId, String mapelId, String semesterId, {String jenis = 'harian'}) async {
    final res = await ApiClient.get('/guru/nilai/siswa-per-kelas',
        queryParams: {'kelas_id': kelasId, 'mata_pelajaran_id': mapelId, 'semester_id': semesterId, 'jenis': jenis});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> inputNilaiMassal(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/nilai/nilai-massal', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getRapor({String? siswaId, String? semesterId}) async {
    final params = <String, String>{};
    if (siswaId != null) params['siswa_id'] = siswaId;
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/guru/rapor', queryParams: params);
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> saveRapor(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/rapor', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPengaduan({int page = 1, int perPage = 20}) async {
    final res = await ApiClient.get('/guru/pengaduan', queryParams: {'page': '$page', 'per_page': '$perPage'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createPengaduan(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/pengaduan', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDataSiswa() async {
    final res = await ApiClient.get('/guru/data-siswa');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRekapAbsensi() async {
    final res = await ApiClient.get('/guru/rekap-absensi');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRekapNilai({String? semesterId}) async {
    final params = <String, String>{};
    if (semesterId != null) params['semester_id'] = semesterId;
    final res = await ApiClient.get('/guru/rekap-nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> saveCatatanWali(Map<String, dynamic> body) async {
    await ApiClient.put('/guru/catatan-wali', body: body);
  }

  static Future<List<dynamic>> getJadwal() async {
    final res = await ApiClient.get('/guru/jadwal');
    return res['data'] as List<dynamic>;
  }
}
