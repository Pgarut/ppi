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

  static Future<List<dynamic>> getAssignments() async {
    final res = await ApiClient.get('/guru/absensi/assignments');
    return res['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> getSiswaPerKelasAbsensi(String kelasId, {String? tanggal, String? mataPelajaranId, String? jam}) async {
    final params = <String, String>{'kelas_id': kelasId};
    if (tanggal != null) params['tanggal'] = tanggal;
    if (mataPelajaranId != null) params['mata_pelajaran_id'] = mataPelajaranId;
    if (jam != null) params['jam'] = jam;
    final res = await ApiClient.get('/guru/absensi/siswa-per-kelas', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRiwayatSesi({int page = 1, int perPage = 20}) async {
    final res = await ApiClient.get('/guru/absensi/riwayat-sesi', queryParams: {'page': '$page', 'per_page': '$perPage'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getDetailSesi(String tanggal, String kelasId, {String? mapelId, String? jam}) async {
    final params = <String, String>{'tanggal': tanggal, 'kelas_id': kelasId};
    if (mapelId != null) params['mata_pelajaran_id'] = mapelId;
    if (jam != null) params['jam'] = jam;
    final res = await ApiClient.get('/guru/absensi/riwayat-sesi/detail', queryParams: params);
    return res['data']?['items'] as List<dynamic>? ?? [];
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

  /// Ambil rapor siswa (aggregate dari nilai PAS/PAT + Harian)
  static Future<Map<String, dynamic>> getRapor({required String siswaId, required String semesterId}) async {
    final res = await ApiClient.get('/guru/rapor', queryParams: {
      'siswa_id': siswaId,
      'semester_id': semesterId,
    });
    return res['data'] as Map<String, dynamic>;
  }

  /// Daftar semester untuk dropdown
  static Future<List<dynamic>> getSemesterList() async {
    final res = await ApiClient.get('/guru/rapor/semester');
    return res['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> getPengaduan({int page = 1, int perPage = 20, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (status != null) params['status'] = status;
    final res = await ApiClient.get('/guru/pengaduan', queryParams: params);
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

  static Future<List<dynamic>> getAssignmentsNilai() async {
    final res = await ApiClient.get('/guru/nilai/assignments');
    return res['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>?> getSemesterAktif() async {
    final res = await ApiClient.get('/guru/nilai/semester-aktif');
    return res['data'] as Map<String, dynamic>?;
  }

  static Future<Map<String, dynamic>> getTemplateNilai(String kelasId, String mapelId, String semesterId) async {
    final res = await ApiClient.get('/guru/nilai/template',
        queryParams: {'kelas_id': kelasId, 'mata_pelajaran_id': mapelId, 'semester_id': semesterId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cekWaliKelas() async {
    final res = await ApiClient.get('/guru/rapor/cek-wali');
    return res['data'] as Map<String, dynamic>;
  }

  /// Ambil data wali kelas: siswa, mapel untuk kelas wali
  static Future<Map<String, dynamic>> getDataWaliRapor() async {
    final res = await ApiClient.get('/guru/rapor/data-wali');
    return res['data'] as Map<String, dynamic>;
  }

  /// Status pengiriman nilai PAS/PAT oleh guru_mapel
  static Future<List<dynamic>> getStatusPengiriman(String semesterId) async {
    final res = await ApiClient.get('/guru/rapor/status-pengiriman', queryParams: {'semester_id': semesterId});
    return res['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> uploadNilaiMassal(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/guru/nilai/upload-massal', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getJadwal() async {
    final res = await ApiClient.get('/guru/jadwal');
    return res['data'] as List<dynamic>;
  }
}
