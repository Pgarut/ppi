import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'jadwal_program_page.dart';
import 'hasil_program_page.dart';

class DaurohMenuPage extends StatelessWidget {
  const DaurohMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Program at-Ta\'wid',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih menu untuk melihat informasi program',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.grey500,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.calendar_month,
                  label: 'Jadwal Program',
                  description: 'Lihat jadwal program at-Ta\'wid yang diikuti',
                  color: AppTheme.primary,
                  onTap: () => _navigateTo(context, const JadwalProgramPage()),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.assessment,
                  label: 'Hasil Program',
                  description: 'Lihat penilaian & nilai hafalan',
                  color: Colors.orange,
                  onTap: () => _navigateTo(context, const HasilProgramPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.grey200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withAlpha(25),
                      color.withAlpha(50),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.grey800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
