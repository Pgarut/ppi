import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';
import '../../../shared/widgets/common_widgets.dart';

class PembayaranSantriPage extends StatefulWidget {
  const PembayaranSantriPage({super.key});

  @override
  State<PembayaranSantriPage> createState() => _PembayaranSantriPageState();
}

class _PembayaranSantriPageState extends State<PembayaranSantriPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = SantriService();

  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _loading = true;
  String _error = '';
  int _page = 1, _totalPages = 1;
  String _currentFilter = 'all'; // 'all', '*', '**', '***'

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await _service.getPembayaran(
        page: _page,
        perPage: 20,
        status: _currentFilter == 'all' ? null : _currentFilter,
      );
      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final pagination = res['pagination'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          if (refresh || _page == 1) {
            _allPayments = items;
          } else {
            _allPayments.addAll(items);
          }
          _totalPages = pagination['total_pages'] ?? 1;
          _loading = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_currentFilter == 'all') {
      _filteredPayments = _allPayments;
    } else {
      _filteredPayments = _allPayments.where((p) => p['status'] == _currentFilter).toList();
    }
  }

  void _onFilterChanged(String? filter) {
    if (filter == null) return;
    setState(() {
      _currentFilter = filter;
      _page = 1;
    });
    _load(refresh: true);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case '*':
        return 'Lunas';
      case '**':
        return 'Proses';
      case '***':
        return 'Belum Bayar';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '*':
        return AppTheme.teal;
      case '**':
        return AppTheme.orange;
      case '***':
        return AppTheme.error;
      default:
        return AppTheme.grey600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '*':
        return Icons.check_circle;
      case '**':
        return Icons.hourglass_top;
      case '***':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatCurrency(dynamic amount) {
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idarat al-Madfu\'at'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Tagihan Aktif'),
            Tab(text: 'Riwayat'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _onFilterChanged,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'all', child: Text('Semua')),
              const PopupMenuItem(value: '*', child: Row(children: [Icon(Icons.check_circle, size: 18, color: AppTheme.teal), SizedBox(width: 8), Text('Lunas')])),
              const PopupMenuItem(value: '**', child: Row(children: [Icon(Icons.hourglass_top, size: 18, color: AppTheme.orange), SizedBox(width: 8), Text('Proses')])),
              const PopupMenuItem(value: '***', child: Row(children: [Icon(Icons.cancel, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Belum Bayar')])),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _load(refresh: true)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _allPayments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error, style: const TextStyle(color: AppTheme.grey600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () => _load(refresh: true), icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(filterActive: true),
          _buildList(filterActive: false),
        ],
      ),
    );
  }

  Widget _buildList({required bool filterActive}) {
    final list = _filteredPayments.where((p) {
      final status = p['status'] as String? ?? '***';
      if (filterActive) {
        return status == '**' || status == '***'; // Proses atau Belum Bayar
      } else {
        return status == '*'; // Lunas
      }
    }).toList();

    if (list.isEmpty) {
      return EmptyState(
        icon: filterActive ? Icons.account_balance_wallet_outlined : Icons.check_circle_outline,
        message: filterActive ? 'Tidak ada tagihan aktif' : 'Belum ada riwayat pembayaran',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length + (_page < _totalPages ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == list.length) {
          if (_loading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
          return Center(
            child: TextButton(onPressed: () { _page++; _load(); }, child: const Text('Muat lebih banyak')),
          );
        }
        final p = list[i];
        final status = p['status'] as String? ?? '***';
        final jumlah = p['jumlah'] as num? ?? 0;
        final jenisNama = p['jenis_nama'] as String? ?? '-';
        final jenisKode = p['jenis_kode'] as String? ?? '';
        final tanggalBayar = p['tanggal_bayar'] as String?;
        final catatan = p['catatan'] as String?;
        final createdAt = p['created_at'] as String?;

        return Card(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)), side: BorderSide(color: AppTheme.grey200)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long, size: 22, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(jenisNama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (jenisKode.isNotEmpty) Text(jenisKode, style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rp ${_formatCurrency(jumlah)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.grey800)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_getStatusIcon(status), size: 12, color: _getStatusColor(status)),
                            const SizedBox(width: 4),
                            Text(_getStatusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getStatusColor(status))),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.grey100),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoRow(icon: Icons.calendar_today, label: 'Dibuat', value: _formatDate(createdAt)),
                    if (tanggalBayar != null && tanggalBayar.isNotEmpty)
                      _InfoRow(icon: Icons.check_circle_outline, label: 'Tgl Bayar', value: _formatDate(tanggalBayar)),
                    if (catatan != null && catatan.isNotEmpty)
                      _InfoRow(icon: Icons.note_outlined, label: 'Catatan', value: catatan),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.grey700)),
      ],
    );
  }
}