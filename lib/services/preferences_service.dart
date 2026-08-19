import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  PreferencesService._internal();
  static final PreferencesService instance = PreferencesService._internal();

  // Storage keys
  static const _keyMapType = 'map_type';
  static const _keyTheme = 'theme_mode';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyLocationTracking = 'location_tracking';
  static const _keyHistoryEnabled = 'history_enabled';
  static const _keyFontSize = 'font_size';
  static const _keyDensity = 'compact_mode';
  static const _keyAnimations = 'animations_enabled';

  // Mapa
  String _mapType = 'normal';

  // Tema y apariencia
  String _theme = 'light';
  double _fontSizeMultiplier = 1.0;
  bool _compactMode = false;
  bool _animationsEnabled = true;

  // Notificaciones y privacidad
  bool _notificationsEnabled = true;
  bool _locationTracking = true;
  bool _historyEnabled = true;

  bool _initialized = false;

  // Getters - Mapa
  String get mapType => _mapType;

  // Getters - Tema y apariencia
  ThemeMode get themeMode =>
      _theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get compactMode => _compactMode;
  bool get animationsEnabled => _animationsEnabled;

  // Getters - Notificaciones y privacidad
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationTracking => _locationTracking;
  bool get historyEnabled => _historyEnabled;

  bool get isInitialized => _initialized;

  Future<void> load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    _mapType = prefs.getString(_keyMapType) ?? 'normal';
    _theme = prefs.getString(_keyTheme) ?? 'light';
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _locationTracking = prefs.getBool(_keyLocationTracking) ?? true;
    _historyEnabled = prefs.getBool(_keyHistoryEnabled) ?? true;
    _fontSizeMultiplier = prefs.getDouble(_keyFontSize) ?? 1.0;
    _compactMode = prefs.getBool(_keyDensity) ?? false;
    _animationsEnabled = prefs.getBool(_keyAnimations) ?? true;

    _initialized = true;
    notifyListeners();
  }

  // Setters - Mapa
  Future<void> setMapType(String value) async {
    if (value == _mapType) return;
    _mapType = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapType, value);
    notifyListeners();
  }

  // Setters - Tema y apariencia
  Future<void> setTheme(String value) async {
    if (value == _theme) return;
    _theme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, value);
    notifyListeners();
  }

  Future<void> setFontSizeMultiplier(double value) async {
    if (value == _fontSizeMultiplier) return;
    _fontSizeMultiplier = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, value);
    notifyListeners();
  }

  Future<void> setCompactMode(bool value) async {
    if (value == _compactMode) return;
    _compactMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDensity, value);
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    if (value == _animationsEnabled) return;
    _animationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAnimations, value);
    notifyListeners();
  }

  // Setters - Notificaciones y privacidad
  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _notificationsEnabled) return;
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> setLocationTracking(bool value) async {
    if (value == _locationTracking) return;
    _locationTracking = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationTracking, value);
    notifyListeners();
  }

  Future<void> setHistoryEnabled(bool value) async {
    if (value == _historyEnabled) return;
    _historyEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHistoryEnabled, value);
    notifyListeners();
  }
}
