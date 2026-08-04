/// Generic wrapper for API responses.
class ApiResponse<T> {
  final T data;
  final String? message;
  final int? totalItems;
  final int? totalPages;
  final int? currentPage;

  const ApiResponse({
    required this.data,
    this.message,
    this.totalItems,
    this.totalPages,
    this.currentPage,
  });

  /// Create ApiResponse from a raw API response map.
  ///
  /// [json] is the full API response: `{data: ..., message: ..., pagination: ...}`.
  /// [fromJson] converts the `data` field to type T.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson, {
    String dataKey = 'data',
  }) {
    final rawData = json[dataKey];
    final data = fromJson(rawData);
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return ApiResponse(
      data: data,
      message: json['message'] as String?,
      totalItems: pagination?['total_items'] as int?,
      totalPages: pagination?['total_pages'] as int?,
      currentPage: pagination?['current_page'] as int?,
    );
  }

  /// Create ApiResponse for a list response with pagination.
  factory ApiResponse.fromPaginated(
    Map<String, dynamic> json,
    T Function(dynamic) fromItem, {
    String itemsKey = 'data',
  }) {
    final rawItems = json[itemsKey] as List<dynamic>? ?? [];
    final items = rawItems.map(fromItem).toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return ApiResponse(
      data: items as T,
      message: json['message'] as String?,
      totalItems: pagination?['total_items'] as int?,
      totalPages: pagination?['total_pages'] as int?,
      currentPage: pagination?['current_page'] as int?,
    );
  }

  bool get hasMore => currentPage != null && totalPages != null && currentPage! < totalPages!;
}
