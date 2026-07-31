import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'jwt_token');
  }

  Future<void> saveBiometricsEnabled(bool enabled) async {
    await storage.write(
      key: 'biometrics_enabled',
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricsEnabled() async {
    final value = await storage.read(key: 'biometrics_enabled');
    return value == 'true';
  }

  Future<void> clearBiometrics() async {
    await storage.delete(key: 'biometrics_enabled');
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null) return false;
    return !isTokenExpired(token);
  }

  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }
      final String payload = parts[1];
      final String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      if (claims.containsKey('exp')) {
        final int exp = claims['exp'] as int;
        final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(expiryDate);
      }

      return false;
    } catch (_) {
      return true;
    }
  }
}

