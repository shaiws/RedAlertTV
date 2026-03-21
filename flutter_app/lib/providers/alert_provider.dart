import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';

class AlertProvider extends ChangeNotifier {
  Alert? _currentAlert;
  bool _isServiceRunning = false;
  String _language = 'en';
  bool _isTV = false;
  Timer? _pollingTimer;
  String? _lastAlertId;

  Alert? get currentAlert => _currentAlert;
  bool get isServiceRunning => _isServiceRunning;
  String get language => _language;
  bool get isTV => _isTV;

  AlertProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  void setIsTV(bool value) {
    _isTV = value;
    notifyListeners();
  }

  void startService() {
    if (_isServiceRunning) return;
    _isServiceRunning = true;
    notifyListeners();
    // Poll immediately, then every second.
    _poll();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  void stopService() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isServiceRunning = false;
    _currentAlert = null;
    _lastAlertId = null;
    notifyListeners();
  }

  Future<void> _poll() async {
    final alert = await AlertService.fetchAlert();
    final newId = alert?.id;

    if (newId != _lastAlertId) {
      _lastAlertId = newId;
      _currentAlert = alert;
      notifyListeners();
    }
  }

  /// Injects a dummy alert for UI testing, auto-clears after 20 seconds.
  void triggerTestAlert() {
    _currentAlert = DummyAlert.create(language: _language);
    notifyListeners();

    Timer(const Duration(seconds: 20), () {
      if (_currentAlert?.isTest ?? false) {
        _currentAlert = null;
        notifyListeners();
      }
    });
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
