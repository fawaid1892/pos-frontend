import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_settings.dart';

/// Provider for receipt customization settings.
///
/// Persists all settings via SharedPreferences as JSON.
class ReceiptSettingsProvider extends ChangeNotifier {
  static const String _key = 'receipt_settings';

  ReceiptSettings _settings = const ReceiptSettings();
  bool _isLoaded = false;

  ReceiptSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  /// Load persisted receipt settings from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = ReceiptSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('ReceiptSettingsProvider.init error: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Update the entire settings object.
  Future<void> updateSettings(ReceiptSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _persist();
  }

  /// Update a single field.
  Future<void> updateField(String field, dynamic value) async {
    switch (field) {
      case 'storeName':
        _settings = _settings.copyWith(storeName: value as String);
        break;
      case 'storeAddress':
        _settings = _settings.copyWith(storeAddress: value as String);
        break;
      case 'storePhone':
        _settings = _settings.copyWith(storePhone: value as String);
        break;
      case 'headerText':
        _settings = _settings.copyWith(headerText: value as String);
        break;
      case 'footerText':
        _settings = _settings.copyWith(footerText: value as String);
        break;
      case 'fontSize':
        _settings = _settings.copyWith(fontSize: (value as num).toDouble());
        break;
      case 'showLogo':
        _settings = _settings.copyWith(showLogo: value as bool);
        break;
      case 'showItemBarcode':
        _settings = _settings.copyWith(showItemBarcode: value as bool);
        break;
      case 'showCashierName':
        _settings = _settings.copyWith(showCashierName: value as bool);
        break;
      case 'showTaxInfo':
        _settings = _settings.copyWith(showTaxInfo: value as bool);
        break;
      case 'paperSize':
        _settings = _settings.copyWith(paperSize: value as String);
        break;
    }
    notifyListeners();
    await _persist();
  }

  /// Reset to defaults.
  Future<void> resetToDefaults() async {
    _settings = const ReceiptSettings();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('ReceiptSettingsProvider._persist error: $e');
    }
  }
}
