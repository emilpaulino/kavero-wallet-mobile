import 'dart:convert';
import '../../../core/constants/api_constants.dart';

import 'package:http/http.dart' as http;

import '../../../core/storage_service.dart';
import '../models/account.dart';

class AccountService {
  final String baseUrl = ApiConstants.baseUrl;

  final storageService = StorageService();

  Future<List<Account>> getAccounts() async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/accounts');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print(response.statusCode);
    print(response.body);

    final List data = jsonDecode(response.body);

    return data.map((json) => Account.fromJson(json)).toList();
  }
}
