/// Generic wrapper for paginated API responses.
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int? totalItems;

  const PaginatedResponse({
    required this.items,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromItem, {
    String itemsKey = 'data',
  }) {
    final rawItems = json[itemsKey] as List<dynamic>? ?? [];
    final items = rawItems.map(fromItem).toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PaginatedResponse(
      items: items,
      currentPage: pagination?['current_page'] as int? ?? 1,
      totalPages: pagination?['total_pages'] as int? ?? 1,
      totalItems: pagination?['total_items'] as int?,
    );
  }

  bool get hasMore => currentPage < totalPages;
}
