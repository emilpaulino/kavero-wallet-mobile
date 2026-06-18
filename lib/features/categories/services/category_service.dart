import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/storage_service.dart';
import '../models/category.dart';
import '../../../core/constants/api_constants.dart';

class CategoryService {
  final storageService = StorageService();

  final String baseUrl = ApiConstants.baseUrl;

  Future<List<Category>> getCategories(String type) async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/categories?type=$type');

    final response = await http.get(
      url,

      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);

    print(response.statusCode);
    print(response.body);

    return data.map<Category>((json) {
      return Category.fromJson(json);
    }).toList();
  }
}
