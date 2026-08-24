import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PembayaranSantriPage extends StatelessWidget {
  const PembayaranSantriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Idarat al-Madfu\'at',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Administrasi Pembayaran',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey500,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Halaman dalam pengembangan',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.grey600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
