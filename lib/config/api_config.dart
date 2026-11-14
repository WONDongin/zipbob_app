import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final configuredUrl = _configuredUrl.trim();

    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    }

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }
}
