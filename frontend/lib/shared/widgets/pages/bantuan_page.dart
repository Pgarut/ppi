import 'package:flutter/material.dart';

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Pusat Bantuan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _section(
          Icons.dashboard_outlined,
          'Dashboard',
          'Halaman utama yang menampilkan ringkasan data dan menu fitur. Gunakan navigasi bawah (Dashboard, Aktivitas, Profil) untuk berpindah halaman.',
        ),
        _section(
          Icons.storage_outlined,
          'Master Data',
          'Kelola data utama seperti Tahun Ajaran, Semester, Jurusan, Tingkat, Kelas, Mata Pelajaran, Asatidz, Santri, dan Ruangan. Tersedia fitur import Excel untuk input massal.',
        ),
        _section(
          Icons.calendar_today_outlined,
          'Absensi',
          'Input dan monitoring kehadiran santri & asatidz. Rekap absensi harian, analisis, dan audit trail tersedia untuk memantau kedisiplinan.',
        ),
        _section(
          Icons.grading_outlined,
          'Nilai',
          'Input nilai santri (tugas, UTS, UAS), validasi, dan monitoring. Asatidz menginput, Wakil Kurikulum dan Admin memonitor & memvalidasi.',
        ),
        _section(
          Icons.description_outlined,
          'Rapor',
          'Cetak rapor santri per semester. Tersedia fitur arsip dan analisis rapor.',
        ),
        _section(
          Icons.schedule_outlined,
          'Penjadwalan',
          'Atur jadwal pelajaran dengan sistem auto-scheduling. Kelola distribusi guru, beban mengajar, dan publikasi jadwal.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.support_agent, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Butuh bantuan lebih lanjut? Hubungi operator madrasah atau tim pengembang.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}