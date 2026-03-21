import 'package:flutter/services.dart';

/// Detects whether the app is running on an Android TV device.
class PlatformService {
  static const _channel = MethodChannel('com.shaiws.redalert/platform');

  static bool? _isAndroidTV;

  /// Returns true when running on Android TV (leanback feature present).
  static Future<bool> isAndroidTV() async {
    if (_isAndroidTV != null) return _isAndroidTV!;
    try {
      final result = await _channel.invokeMethod<bool>('isAndroidTV');
      _isAndroidTV = result ?? false;
    } on PlatformException {
      _isAndroidTV = false;
    }
    return _isAndroidTV!;
  }
}
