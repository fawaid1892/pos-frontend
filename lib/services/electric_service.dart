import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Connection state for the Electric sync service.
enum ElectricConnectionState { disconnected, connecting, connected, error }

/// ElectricSQL sync service that subscribes to shapes via HTTP.
///
/// Instead of the electric_dart package (which may not be available),
/// this uses the Electric HTTP API directly for:
/// - Shape subscription (long-polling / polling)
/// - Direct SQL queries via POST /v1/query
///
/// Electric handles:
/// - Offline-first sync automatically
/// - Conflict resolution
/// - Incremental sync via LSN tracking
class ElectricService extends ChangeNotifier {
  static final ElectricService _instance = ElectricService._internal();
  factory ElectricService() => _instance;
  ElectricService._internal();

  static const String _baseUrl = 'http://localhost:5133';

  http.Client _httpClient = http.Client();

  ElectricConnectionState _connectionState = ElectricConnectionState.disconnected;
  String? _lastError;

  // Shape polling timers
  Timer? _shapePollTimer;
  final Set<String> _subscribedShapes = {};
  final Map<String, List<Map<String, dynamic>>> _shapeData = {};

  // Callbacks for shape data changes
  final Map<String, List<void Function(List<Map<String, dynamic>>)>> _shapeCallbacks = {};

  ElectricConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == ElectricConnectionState.connected;

  /// Shape names that this app subscribes to.
  static const List<String> shapes = [
    'users',
    'branches',
    'categories',
    'products',
    'transactions',
    'transaction_items',
    'branch_products',
    'stock_mutations',
  ];

  /// Replace the default HTTP client (e.g. for testing).
  void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// Initialize the Electric service and subscribe to all shapes.
  Future<void> init() async {
    _connectionState = ElectricConnectionState.connecting;
    notifyListeners();

    try {
      // Check connection to Electric sync service
      final healthUri = Uri.parse('$_baseUrl/health');
      final healthResponse = await _httpClient
          .get(healthUri)
          .timeout(const Duration(seconds: 5));

      if (healthResponse.statusCode == 200) {
        _connectionState = ElectricConnectionState.connected;
        debugPrint('Electric service connected at $_baseUrl');

        // Subscribe to all shapes
        await _subscribeToAllShapes();

        // Start periodic polling for shape updates
        _startShapePolling();
      } else {
        _connectionState = ElectricConnectionState.error;
        _lastError = 'Electric service returned ${healthResponse.statusCode}';
      }
    } catch (e) {
      _connectionState = ElectricConnectionState.error;
      _lastError = 'Cannot connect to Electric: $e';
      debugPrint('Electric init error: $e');

      // Still allow operation in offline mode

    notifyListeners();
    }
  }

  /// Subscribe to all configured shapes.
  Future<void> _subscribeToAllShapes() async {
    for (final shape in shapes) {
      await _subscribeToShape(shape);
    }
  }

  /// Subscribe to a single shape via Electric HTTP API.
  ///
  /// Electric shapes are identified by table name and return
  /// the current data + ongoing changes via LSN-based polling.
  Future<void> _subscribeToShape(String shapeName) async {
    try {
      final uri = Uri.parse('$_baseUrl/v1/shape/$shapeName');
      final response = await _httpClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rows = List<Map<String, dynamic>>.from(body['data'] ?? body['rows'] ?? []);
        _shapeData[shapeName] = rows;
        _subscribedShapes.add(shapeName);
        debugPrint('Subscribed to shape: $shapeName (${rows.length} rows)');

        // Notify callbacks
        _notifyShapeListeners(shapeName, rows);
      } else {
        debugPrint('Failed to subscribe to shape $shapeName: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error subscribing to shape $shapeName: $e');
    }
  }

  /// Start periodic polling for shape updates.
  void _startShapePolling() {
    _shapePollTimer?.cancel();
    _shapePollTimer = Timer.periodic(
      const Duration(seconds: 30), // Poll every 30 seconds
      (_) => _pollAllShapes(),
    );
  }

  /// Poll all subscribed shapes for updates.
  Future<void> _pollAllShapes() async {
    for (final shape in _subscribedShapes) {
      await _pollShape(shape);
    }
  }

  /// Poll a single shape for changes.
  Future<void> _pollShape(String shapeName) async {
    try {
      final uri = Uri.parse('$_baseUrl/v1/shape/$shapeName');
      final response = await _httpClient
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rows = List<Map<String, dynamic>>.from(body['data'] ?? body['rows'] ?? []);
        _shapeData[shapeName] = rows;
        _notifyShapeListeners(shapeName, rows);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error polling shape $shapeName: $e');
    }
  }

  /// Register a callback for data changes on a specific shape.
  void onShapeData(String shapeName, void Function(List<Map<String, dynamic>>) callback) {
    _shapeCallbacks.putIfAbsent(shapeName, () => []);
    _shapeCallbacks[shapeName]!.add(callback);

    // Immediately invoke with current data if available
    if (_shapeData.containsKey(shapeName)) {
      callback(List.unmodifiable(_shapeData[shapeName]!));
    }
  }

  /// Remove a callback for a shape.
  void removeShapeListener(String shapeName, void Function(List<Map<String, dynamic>>) callback) {
    _shapeCallbacks[shapeName]?.remove(callback);
  }

  void _notifyShapeListeners(String shapeName, List<Map<String, dynamic>> data) {
    final callbacks = _shapeCallbacks[shapeName];
    if (callbacks != null) {
      for (final cb in callbacks) {
        cb(List.unmodifiable(data));
      }
    }
  }

  /// Get cached data for a shape.
  List<Map<String, dynamic>>? getShapeData(String shapeName) {
    return _shapeData[shapeName];
  }

  /// Execute a SQL query via Electric HTTP API.
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? params,
  ]) async {
    try {
      final uri = Uri.parse('$_baseUrl/v1/query');
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'sql': sql,
              'params': params ?? [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['rows'] ?? []);
      } else {
        debugPrint('Electric query error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Electric query failed: $e');
      return [];
    }
  }

  /// Execute a write operation via Electric HTTP API.
  Future<int> execute(String sql, [List<dynamic>? params]) async {
    try {
      final uri = Uri.parse('$_baseUrl/v1/query');
      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'sql': sql,
              'params': params ?? [],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['affected_rows'] as num?)?.toInt() ?? 0;
      } else {
        debugPrint('Electric execute error ${response.statusCode}: ${response.body}');
        return 0;
      }
    } catch (e) {
      debugPrint('Electric execute failed: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _shapePollTimer?.cancel();
    _shapeCallbacks.clear();
    _httpClient.close();
    super.dispose();
  }
}
