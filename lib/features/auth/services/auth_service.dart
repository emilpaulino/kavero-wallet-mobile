import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/storage_service.dart';
import '../../../core/constants/api_constants.dart';

class AuthService {
  final String baseUrl = ApiConstants.baseUrl;

  final storageService = StorageService();

  Future<void> login({required String email, required String password}) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid credentials');
    }

    final data = jsonDecode(response.body);
    final token = data['token'];

    if (token == null) {
      throw Exception('Token is null');
    }

    await storageService.saveToken(token);
    print('TOKEN SAVED');
  }

  Future<void> register({
    required String name,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Registration failed');
    }

    final data = jsonDecode(response.body);
    final token = data['token'];

    if (token == null) {
      throw Exception('Token is null');
    }

    await storageService.saveToken(token);
  }
}
