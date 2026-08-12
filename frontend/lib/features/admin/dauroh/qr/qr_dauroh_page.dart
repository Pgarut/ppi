import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_form_widgets.dart';

class QrDaurohPage extends StatefulWidget {
  const QrDaurohPage({super.key});

  @override
  State<QrDaurohPage> createState() => _QrDaurohPageState();
}

class _QrDaurohPageState extends State<QrDaurohPage> {
  Map<String, dynamic>? _qrInfo;
  Map<String, dynamic>? _generatedQR;
  List<Map<String, dynamic>> _jadwalList = [];
  int? _selectedJadwalId;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        DaurohService.getQRInfo(),
        DaurohService.listJadwal(perPage: 100),
      ]);
      if (mounted) {
        setState(() {
          _qrInfo = results[0];
          _jadwalList = (results[1]['items'] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _generateQR() async {
    if (_selectedJadwalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal terlebih dahulu')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final result = await DaurohService.generateQR(_selectedJadwalId!);
      if (mounted) {
        setState(() {
          _generatedQR = result;
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate QR: $e')),
        );
      }
    }
  }

  Future<void> _printQR() async {
    final token = _qrInfo?['token'] ?? 'PPI_DAUROH_QR_2026';
    final jadwal = _generatedQR?['jadwal'];

    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.nunitoRegular(),
      bold: await PdfGoogleFonts.nunitoBold(),
    );

    final qrImage = await QrPainter(
      data: token,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    ).toImage(300);
    final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
    final qrBytes = byteData!.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'ABSENSI AT-TA\'WID',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'MA Persis Garut',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Container(
              width: 200,
              height: 200,
              child: pw.Image(pw.MemoryImage(qrBytes)),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Token: $token',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          if (jadwal != null) ...[
            pw.SizedBox(height: 24),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Informasi Jadwal',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  _pdfInfoRow('Program', '${jadwal['program'] ?? '-'}'),
                  pw.SizedBox(height: 4),
                  _pdfInfoRow('Musyrifah', '${jadwal['musyrifah'] ?? '-'}'),
                  pw.SizedBox(height: 4),
                  _pdfInfoRow('Jadwal', '${jadwal['hari'] ?? '-'}, ${jadwal['jam_mulai'] ?? ''} - ${jadwal['jam_selesai'] ?? ''}'),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Pindai QR Code ini untuk melakukan absensi',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QR Code at-Ta\'wid',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generate QR Code untuk absensi musyrifah',
            style: TextStyle(fontSize: 13, color: AppTheme.grey500),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Form
                Expanded(
                  flex: 2,
                  child: _buildFormCard(),
                ),
                const SizedBox(width: 24),
                // Right: QR Preview
                Expanded(
                  flex: 3,
                  child: _buildQRPreview(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Generate QR',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DaurohDropdown<int>(
            value: _selectedJadwalId,
            label: 'Pilih Jadwal',
            icon: Icons.calendar_month_outlined,
            items: _jadwalList.map((j) => DropdownMenuItem<int>(
              value: j['id'] as int,
              child: Text(
                '${j['nama_program']} - ${j['hari']} ${j['jam_mulai']}-${j['jam_selesai']}',
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (v) => setState(() {
              _selectedJadwalId = v;
              _generatedQR = null;
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generateQR,
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.qr_code_2, size: 18),
              label: Text(_generating ? 'Generating...' : 'Generate QR'),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // QR Token Info
          if (_qrInfo != null) ...[
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.grey500),
                SizedBox(width: 6),
                Text(
                  'QR Token (Statis):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _qrInfo!['token'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _qrInfo!['token'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token disalin')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Token ini dicetak pada QR. Musyrifah memindai QR untuk melakukan absensi.',
              style: TextStyle(fontSize: 12, color: AppTheme.grey500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Preview QR Code',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_generatedQR != null)
                OutlinedButton.icon(
                  onPressed: _printQR,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Cetak'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _generatedQR != null
                ? _buildQRContent()
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2, size: 80, color: AppTheme.grey300),
                        SizedBox(height: 16),
                        Text(
                          'Pilih jadwal dan klik Generate QR',
                          style: TextStyle(color: AppTheme.grey500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    final token = _qrInfo?['token'] ?? 'PPI_DAUROH_QR_2026';
    final jadwal = _generatedQR?['jadwal'];

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ABSENSI AT-TA\'WID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('MA Persis Garut', style: TextStyle(fontSize: 14, color: AppTheme.grey600)),
            const SizedBox(height: 24),
            QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.grey800,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.grey800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Text(
                token,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (jadwal != null) ...[
              Text(
                jadwal['program'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Musyrifah: ${jadwal['musyrifah'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
              ),
              const SizedBox(height: 4),
              Text(
                '${jadwal['hari'] ?? '-'}, ${jadwal['jam_mulai'] ?? ''} - ${jadwal['jam_selesai'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
