import '../../../core/network/api_client.dart';

class MusyrifahService {
  // ─── DASHBOARD ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiClient.get('/musyrifah/dashboard');
    return res['data'] as Map<String, dynamic>;
  }

  // ─── PROFIL ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfil() async {
    final res = await ApiClient.get('/musyrifah/profil');
    return res['data'] as Map<String, dynamic>;
  }

  // ─── JADWAL ─────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getJadwal({String? hari, String? programId}) async {
    final params = <String, String>{};
    if (hari != null && hari.isNotEmpty) params['hari'] = hari;
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    final res = await ApiClient.get('/musyrifah/jadwal', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  // ─── ABSENSI ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanAbsensi({
    required String token,
    int? jadwalId,
  }) async {
    final body = <String, dynamic>{'token': token};
    if (jadwalId != null) body['jadwal_id'] = jadwalId;
    final res = await ApiClient.post('/musyrifah/absensi/scan', body: body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> listAbsensi({
    int page = 1,
    int perPage = 20,
    String? bulan,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (bulan != null && bulan.isNotEmpty) params['bulan'] = bulan;
    final res = await ApiClient.get('/musyrifah/absensi', queryParams: params);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<void> inputAbsensiSantri({
    required int jadwalId,
    required int santriId,
    required String status,
    String? keterangan,
  }) async {
    final body = <String, dynamic>{
      'jadwal_id': jadwalId,
      'santri_id': santriId,
      'status': status,
    };
    if (keterangan != null) body['keterangan'] = keterangan;
    await ApiClient.post('/musyrifah/absensi/santri', body: body);
  }

  // ─── NILAI ──────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listNilai({
    String? programId,
    String? kelasId,
    String? search,
  }) async {
    final params = <String, String>{};
    if (programId != null && programId.isNotEmpty) params['program_id'] = programId;
    if (kelasId != null && kelasId.isNotEmpty) params['kelas_id'] = kelasId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.get('/musyrifah/nilai', queryParams: params);
    return (res['data'] as List).cast<Map<String, dynamic>>();
  }

  static Future<void> inputNilai({
    required int programId,
    required int santriId,
    double? nilaiHafalan,
    double? nilaiBacaan,
    String? catatan,
  }) async {
    final body = <String, dynamic>{
      'program_id': programId,
      'santri_id': santriId,
    };
    if (nilaiHafalan != null) body['nilai_hafalan'] = nilaiHafalan;
    if (nilaiBacaan != null) body['nilai_bacaan'] = nilaiBacaan;
    if (catatan != null) body['catatan'] = catatan;
    await ApiClient.post('/musyrifah/nilai', body: body);
  }

  static Future<void> updateNilai({
    required int id,
    double? nilaiHafalan,
    double? nilaiBacaan,
    String? catatan,
  }) async {
    final body = <String, dynamic>{};
    if (nilaiHafalan != null) body['nilai_hafalan'] = nilaiHafalan;
    if (nilaiBacaan != null) body['nilai_bacaan'] = nilaiBacaan;
    if (catatan != null) body['catatan'] = catatan;
    await ApiClient.put('/musyrifah/nilai/$id', body: body);
  }
}
