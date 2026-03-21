import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';

class AlertService {
  static const _url =
      'https://www.oref.org.il/WarningMessages/alert/alerts.json';

  static const _headers = {
    'Referer': 'https://www.oref.org.il/',
    'X-Requested-With': 'XMLHttpRequest',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  /// Fetches the current alert from the Oref API.
  /// Returns [Alert] when an alert is active, or null when there are no alerts.
  static Future<Alert?> fetchAlert() async {
    try {
      final response = await http
          .get(Uri.parse(_url), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      // The API returns UTF-8 with BOM (UTF-8-SIG).
      // Decode bytes manually to handle the BOM.
      final bytes = response.bodyBytes;
      var body = utf8.decode(bytes, allowMalformed: true);

      // Strip UTF-8 BOM character (\uFEFF) if present.
      body = body.replaceAll('\uFEFF', '').trim();

      // When quiet (no alerts), the API returns an empty string.
      if (body.isEmpty) return null;

      // Some responses contain only null bytes or whitespace.
      if (body.replaceAll('\x00', '').trim().isEmpty) return null;

      final json = jsonDecode(body) as Map<String, dynamic>;
      final alert = Alert.fromJson(json);

      // Guard against empty data list.
      if (alert.data.isEmpty) return null;

      return alert;
    } catch (_) {
      return null;
    }
  }
}
