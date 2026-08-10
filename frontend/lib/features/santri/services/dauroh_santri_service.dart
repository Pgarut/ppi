import '../../../core/network/api_client.dart';

class DaurohSantriService {
  Future<List<Map<String, dynamic>>> getProgram() async {
    final response = await ApiClient.get('/siswa/dauroh/program');
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getNilai({String? programId}) async {
    final queryParams = <String, String>{};
    if (programId != null) queryParams['program_id'] = programId;
    final response = await ApiClient.get('/siswa/dauroh/nilai', queryParams: queryParams);
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAbsensi({
    String? bulan,
    String? tahun,
  }) async {
    final queryParams = <String, String>{};
    if (bulan != null) queryParams['bulan'] = bulan;
    if (tahun != null) queryParams['tahun'] = tahun;
    final response = await ApiClient.get('/siswa/dauroh/absensi', queryParams: queryParams);
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }
}