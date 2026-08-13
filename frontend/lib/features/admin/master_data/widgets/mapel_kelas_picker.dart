import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/guru_mapel_kelas_model.dart';
import '../../../../shared/widgets/common_widgets.dart';

class MapelKelasPicker extends StatefulWidget {
  final List<Map<String, dynamic>> mapelList;
  final List<Map<String, dynamic>> kelasList;
  final List<GuruMapelKelas> assignments;
  final ValueChanged<List<GuruMapelKelas>> onChanged;

  const MapelKelasPicker({
    super.key,
    required this.mapelList,
    required this.kelasList,
    required this.assignments,
    required this.onChanged,
  });

  @override
  State<MapelKelasPicker> createState() => _MapelKelasPickerState();
}

class _MapelKelasPickerState extends State<MapelKelasPicker> {
  late List<_MapelKelasRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildRowsFromAssignments();
  }

  @override
  void didUpdateWidget(covariant MapelKelasPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assignments != widget.assignments) {
      _rows = _buildRowsFromAssignments();
    }
  }

  List<_MapelKelasRow> _buildRowsFromAssignments() {
    final map = <int, Set<int>>{};
    for (final a in widget.assignments) {
      map.putIfAbsent(a.mataPelajaranId, () => {}).add(a.kelasId);
    }
    return map.entries.map((e) => _MapelKelasRow(
      mapelId: e.key,
      kelasIds: Set.from(e.value),
    )).toList();
  }

  void _notifyChange() {
    final result = <GuruMapelKelas>[];
    for (final row in _rows) {
      for (final kelasId in row.kelasIds) {
        result.add(GuruMapelKelas(
          guruId: 0,
          mataPelajaranId: row.mapelId,
          kelasId: kelasId,
        ));
      }
    }
    widget.onChanged(result);
  }

  void _addRow() {
    setState(() {
      _rows.add(_MapelKelasRow(mapelId: 0, kelasIds: {}));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index);
    });
    _notifyChange();
  }

  void _updateRowMapel(int index, int? mapelId) {
    if (mapelId == null) return;
    setState(() {
      _rows[index].mapelId = mapelId;
    });
    _notifyChange();
  }

  void _toggleKelas(int index, int kelasId) {
    setState(() {
      if (_rows[index].kelasIds.contains(kelasId)) {
        _rows[index].kelasIds.remove(kelasId);
      } else {
        _rows[index].kelasIds.add(kelasId);
      }
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return DataCard(
      header: Row(children: [
        Icon(Icons.book_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Mata Pelajaran & Kelas yang Diampu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        if (_rows.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_rows.length} Mapel',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
            ),
          ),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_rows.isEmpty)
            InkWell(
              onTap: _addRow,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.grey200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 32, color: AppTheme.grey400),
                    SizedBox(height: 8),
                    Text('Tap untuk menambah mata pelajaran', style: TextStyle(fontSize: 13, color: AppTheme.grey500)),
                  ],
                ),
              ),
            )
          else ...[
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 180, child: Text('Mata Pelajaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700))),
                  SizedBox(width: 8),
                  Expanded(child: Text('Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700))),
                  SizedBox(width: 40),
                ],
              ),
            ),
            // Rows
            ...List.generate(_rows.length, (index) {
              final row = _rows[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.grey200)),
                ),
                child: Row(
                  children: [
                    // Mapel dropdown
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<int>(
                        value: row.mapelId > 0 ? row.mapelId : null,
                        isDense: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        hint: const Text('Pilih Mapel', style: TextStyle(fontSize: 13)),
                        items: widget.mapelList.map((m) => DropdownMenuItem(
                          value: m['id'] as int,
                          child: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) => _updateRowMapel(index, v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Kelas chips
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.kelasList.map((k) {
                          final kelasId = k['id'] as int;
                          final isSelected = row.kelasIds.contains(kelasId);
                          return FilterChip(
                            label: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (_) => _toggleKelas(index, kelasId),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            selectedColor: AppTheme.primaryLight,
                            checkmarkColor: AppTheme.primary,
                          );
                        }).toList(),
                      ),
                    ),
                    // Delete button
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                        onPressed: () => _removeRow(index),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Add button
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Mapel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapelKelasRow {
  int mapelId;
  final Set<int> kelasIds;

  _MapelKelasRow({required this.mapelId, required this.kelasIds});
}
