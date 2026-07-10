import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/storage_service.dart';
import '../models/user_profile.dart';

class ProfileService {
  final String baseUrl = ApiConstants.baseUrl;

  final StorageService storageService = StorageService();

  Future<UserProfile> getProfile() async {
    final token = await storageService.getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    final data = jsonDecode(response.body);

    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String lastName,
    String? profilePhoto,
  }) async {
    final token = await storageService.getToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'lastName': lastName,
        'profilePhoto': profilePhoto,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }

    final data = jsonDecode(response.body);

    return UserProfile.fromJson(data);
  }


}
