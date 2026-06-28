import 'dart:async';
import 'package:flutter/foundation.dart';
import 'electric_service.dart';

/// Provider that syncs ElectricService state for UI.
///
/// Electric handles sync automatically via shape subscriptions.
/// This provider simply exposes the connection state to the UI.
class SyncProvider extends ChangeNotifier {
  final ElectricService _electricService = ElectricService();

  ElectricConnectionState _connectionState = ElectricConnectionState.disconnected;
  String? _lastError;
  int _shapeCount = 0;

  ElectricService get electricService => _electricService;
  ElectricConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == ElectricConnectionState.connected;
  bool get isSyncing => _connectionState == ElectricConnectionState.connecting;
  int get shapeCount => _shapeCount;

  /// Initialize the provider.
  Future<void> init() async {
    // Listen to ElectricService changes
    _electricService.addListener(_onElectricServiceChanged);

    // Initialize the Electric service
    await _electricService.init();

    // Sync initial state
    _connectionState = _electricService.connectionState;
    _lastError = _electricService.lastError;
    _shapeCount = ElectricService.shapes.length;

    notifyListeners();
  }

  void _onElectricServiceChanged() {
    _connectionState = _electricService.connectionState;
    _lastError = _electricService.lastError;
    notifyListeners();
  }

  @override
  void dispose() {
    _electricService.removeListener(_onElectricServiceChanged);
    _electricService.dispose();
    super.dispose();
  }
}
