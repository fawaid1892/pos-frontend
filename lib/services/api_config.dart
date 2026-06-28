/// Central API configuration for the POS application.
///
/// All backend endpoints are derived from [baseUrl].
/// Override via environment or local config at runtime.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API.
  /// Change this to your deployed server URL in production.
  static const String baseUrl = 'http://localhost:3000';

  /// API version prefix.
  static const String apiPrefix = '/api/v1';

  /// Timeout duration for HTTP requests.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// ── ElectricSQL Sync Endpoints ──

  /// Electric sync service base URL (runs on Docker, port 5133).
  static const String electricBaseUrl = 'http://localhost:5133';

  /// Shape URL for a given table name.
  static String shapeUrl(String table) => '$electricBaseUrl/v1/shape/$table';

  /// Query endpoint for executing SQL via Electric HTTP API.
  static String get queryUrl => '$electricBaseUrl/v1/query';

  /// ── Sync Endpoints (Legacy — kept for reference) ──

  static String get syncPushUrl => '$baseUrl$apiPrefix/sync/push';
  static String get syncPullUrl => '$baseUrl$apiPrefix/sync/pull';
  static String get syncResolveUrl => '$baseUrl$apiPrefix/sync/resolve';

  /// Build pull URL with `since` timestamp.
  static String syncPullUrlWithSince(String since) =>
      '$syncPullUrl?since=${Uri.encodeQueryComponent(since)}';

  /// Build conflict detail URL for a specific record.
  static String conflictDetailUrl(String table, String recordId) =>
      '$baseUrl$apiPrefix/sync/conflict/$table/$recordId';
}
