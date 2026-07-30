import 'package:flutter_test/flutter_test.dart';
import 'package:kavero_wallet_mobile/core/storage_service.dart';

void main() {
  group('StorageService Token Validation Tests', () {
    final storageService = StorageService();

    test('isTokenExpired should return true for invalid token format', () {
      expect(storageService.isTokenExpired('invalid_token'), isTrue);
      expect(storageService.isTokenExpired('header.payload'), isTrue);
    });

    test('isTokenExpired should return true for expired token', () {
      // payload: {"email":"test@example.com","exp":946684800} (Year 2000)
      // Base64Url representation: eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjk0NjY4NDgwMH0
      const expiredToken = 'header.eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjk0NjY4NDgwMH0.signature';
      expect(storageService.isTokenExpired(expiredToken), isTrue);
    });

    test('isTokenExpired should return false for active (non-expired) token', () {
      // payload: {"email":"test@example.com","exp":2058057600} (Year 2035)
      // Base64Url representation: eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjIwNTgwNTc2MDB9
      const activeToken = 'header.eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjIwNTgwNTc2MDB9.signature';
      expect(storageService.isTokenExpired(activeToken), isFalse);
    });

    test('isTokenExpired should return false if no exp claim is present', () {
      // payload: {"email":"test@example.com"}
      // Base64Url representation: eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20ifQ
      const noExpToken = 'header.eyJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20ifQ.signature';
      expect(storageService.isTokenExpired(noExpToken), isFalse);
    });
  });
}
