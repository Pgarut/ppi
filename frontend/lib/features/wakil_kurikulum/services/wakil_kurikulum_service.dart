import '../../../core/network/api_client.dart';

class WakilKurikulumService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/wakil-kurikulum/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getJadwal({int page = 1, int perPage = 50}) async {
    final res = await ApiClient.get('/wakil-kurikulum/jadwal', queryParams: {'page': '$page', 'per_page': '$perPage'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createJadwal(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateJadwal(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/wakil-kurikulum/jadwal/$id', body: body);
  }

  static Future<void> deleteJadwal(int id) async {
    await ApiClient.delete('/wakil-kurikulum/jadwal/$id');
  }

  static Future<Map<String, dynamic>> getReferensi() async {
    final res = await ApiClient.get('/wakil-kurikulum/referensi');
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getGuruByKelasMapel(String kelasId, String mapelId) async {
    final res = await ApiClient.get('/wakil-kurikulum/guru-by-kelas-mapel',
        queryParams: {'kelas_id': kelasId, 'mata_pelajaran_id': mapelId});
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getKesiapanGuru(int guruId, int semesterId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kesiapan',
        queryParams: {'semester_id': '$semesterId', 'guru_id': '$guruId'});
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getJpSlots() async {
    final res = await ApiClient.get('/wakil-kurikulum/jp-slots');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> generateJadwal(int semesterId) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal/generate', body: {'semester_id': semesterId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetJadwal(int semesterId) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal/reset', body: {'semester_id': semesterId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> publikasiJadwal(int semesterId) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal/publikasi', body: {'semester_id': semesterId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getJadwalPerKelas(String kelasId, String semesterId) async {
    final res = await ApiClient.get('/wakil-kurikulum/jadwal-per-kelas',
        queryParams: {'kelas_id': kelasId, 'semester_id': semesterId});
    return res['data'] as List<dynamic>;
  }

  // ── Kesiapan Mengajar Guru ──

  static Future<List<dynamic>> getKesiapan(int semesterId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kesiapan', queryParams: {'semester_id': '$semesterId'});
    return res['data'] as List<dynamic>;
  }

  static Future<void> updateKesiapan(int guruId, Map<String, dynamic> body) async {
    await ApiClient.put('/wakil-kurikulum/kesiapan/$guruId', body: body);
  }

  static Future<Map<String, dynamic>> batchUpdateKesiapan(Map<String, dynamic> body) async {
    final res = await ApiClient.put('/wakil-kurikulum/kesiapan', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Beban Mengajar ──

  static Future<List<dynamic>> getBebanMengajar(int semesterId) async {
    final res = await ApiClient.get('/wakil-kurikulum/beban-mengajar', queryParams: {'semester_id': '$semesterId'});
    return res['data'] as List<dynamic>;
  }

  // ── Wali Kelas ──

  static Future<List<dynamic>> getWaliKelas() async {
    final res = await ApiClient.get('/wakil-kurikulum/wali-kelas');
    return res['data'] as List<dynamic>;
  }

  // ── Simpan Jadwal (batch) ──

  static Future<Map<String, dynamic>> simpanJadwal(List<Map<String, dynamic>> jadwal) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal/simpan', body: {'jadwal': jadwal});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> cekBentrok(Map<String, dynamic> data) async {
    final res = await ApiClient.post('/wakil-kurikulum/jadwal/cek-bentrok', body: data);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getJadwalGuru(String guruId, String semesterId) async {
    final res = await ApiClient.get('/wakil-kurikulum/jadwal-guru',
        queryParams: {'guru_id': guruId, 'semester_id': semesterId});
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getBobotNilai() async {
    final res = await ApiClient.get('/wakil-kurikulum/bobot-nilai');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createBobotNilai(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/wakil-kurikulum/bobot-nilai', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> updateBobotNilai(int id, Map<String, dynamic> body) async {
    await ApiClient.put('/wakil-kurikulum/bobot-nilai/$id', body: body);
  }

  static Future<void> deleteBobotNilai(int id) async {
    await ApiClient.delete('/wakil-kurikulum/bobot-nilai/$id');
  }

  static Future<Map<String, dynamic>> getMonitoringNilai({
    int page = 1, 
    int perPage = 20,
    String? kelasId,
    String? mapelId,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{
      'page': '$page', 
      'per_page': '$perPage',
    };
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (mapelId != null && mapelId.isNotEmpty) params['mata_pelajaran_id'] = mapelId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/wakil-kurikulum/monitoring-nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getStatusPengumpulan() async {
    final res = await ApiClient.get('/wakil-kurikulum/status-pengumpulan');
    return res['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getKenaikanKelas() async {
    final res = await ApiClient.get('/wakil-kurikulum/kenaikan-kelas');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> prosesKenaikan(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/wakil-kurikulum/kenaikan-kelas/proses', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getCalonNaikKelas(String kelasId, String tahunAjaranId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kenaikan-kelas/calon',
        queryParams: {'kelas_id': kelasId, 'tahun_ajaran_id': tahunAjaranId});
    return res['data'] as List<dynamic>;
  }

  // ── Batch Processing ──

  static Future<Map<String, dynamic>> getCalonBatch(String kelasId, String tahunAjaranId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kenaikan-kelas/calon-batch',
        queryParams: {'kelas_id': kelasId, 'tahun_ajaran_id': tahunAjaranId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getKelasTujuan(String dariKelasId, String tahunAjaranId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kenaikan-kelas/kelas-tujuan',
        queryParams: {'dari_kelas_id': dariKelasId, 'tahun_ajaran_id': tahunAjaranId});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> prosesBatch(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/wakil-kurikulum/kenaikan-kelas/proses-batch', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getPengaturanKenaikan(int tahunAjaranId) async {
    final res = await ApiClient.get('/wakil-kurikulum/kenaikan-kelas/pengaturan',
        queryParams: {'tahun_ajaran_id': '$tahunAjaranId'});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> savePengaturanKenaikan(Map<String, dynamic> body) async {
    await ApiClient.post('/wakil-kurikulum/kenaikan-kelas/pengaturan', body: body);
  }

  static Future<List<dynamic>> getAlumni() async {
    final res = await ApiClient.get('/wakil-kurikulum/alumni');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createAlumni(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/wakil-kurikulum/alumni', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getLaporan(String jenis) async {
    final res = await ApiClient.get('/wakil-kurikulum/laporan/$jenis');
    return res['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getAbsensiGuru({int page = 1, int perPage = 20, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/wakil-kurikulum/absensi/guru', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAbsensiSiswa({int page = 1, int perPage = 20, String? kelasId, String? tanggal, String? status}) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await ApiClient.get('/wakil-kurikulum/absensi/siswa', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRekapAbsensi({String? tanggalMulai, String? tanggalSelesai, String? kelasId}) async {
    final params = <String, String>{};
    if (tanggalMulai != null && tanggalMulai.isNotEmpty) params['tanggal_mulai'] = tanggalMulai;
    if (tanggalSelesai != null && tanggalSelesai.isNotEmpty) params['tanggal_selesai'] = tanggalSelesai;
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    final res = await ApiClient.get('/wakil-kurikulum/absensi/rekap', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Dauroh Monitoring Nilai ──

  static Future<Map<String, dynamic>> getDaurohFilters() async {
    final res = await ApiClient.get('/wakil-kurikulum/dauroh/filters');
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
    final res = await ApiClient.get('/wakil-kurikulum/dauroh/nilai', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }
}
