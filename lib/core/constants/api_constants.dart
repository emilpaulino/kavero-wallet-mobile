import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://100.82.41.21:8080';
    }
    return 'http://100.82.41.21:8080';
  }
}
