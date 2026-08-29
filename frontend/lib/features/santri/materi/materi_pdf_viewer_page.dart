import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import '../../../core/theme/app_theme.dart';

class MateriPdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const MateriPdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<MateriPdfViewerPage> createState() => _MateriPdfViewerPageState();
}

class _MateriPdfViewerPageState extends State<MateriPdfViewerPage> {
  PdfController? _controller;
  bool _loading = true;
  String? _error;
  int? _currentPage;
  int? _pagesCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    // Deteksi Google Drive share link dan konversi ke direct download
    final driveMatch = RegExp(
      r'(?:drive\.google\.com/(?:file/d/|open\?id=|uc\?id=|uc\?export=preview&id=))([\w\-_]{10,})',
    ).firstMatch(trimmed);
    if (driveMatch != null) {
      final fileId = driveMatch.group(1)!;
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return trimmed;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(_normalizeUrl(widget.url));
      final res = await http.get(uri).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        throw Exception('Gagal mengunduh materi (HTTP ${res.statusCode})');
      }
      // Latih format kode langsung download Drive: beberapa response berbentuk text biasa
      final controller = PdfController(
        document: PdfDocument.openData(res.bodyBytes),
      );
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          if (_pagesCount != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage ?? 1} / $_pagesCount',
                  style: const TextStyle(fontSize: 13, color: AppTheme.grey500),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            PdfView(
              controller: _controller!,
              scrollDirection: Axis.vertical,
              backgroundDecoration: const BoxDecoration(
                color: Color(0xFFEBEBEB),
              ),
              onDocumentLoaded: (doc) {
                if (!mounted) return;
                setState(() => _pagesCount = doc.pagesCount);
              },
              onPageChanged: (page) {
                if (!mounted) return;
                setState(() => _currentPage = page);
              },
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null && !_loading) _buildError(_error!),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_error != null) {
                  setState(() => _error = null);
                  _load();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
