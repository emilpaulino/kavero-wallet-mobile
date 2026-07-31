import 'dart:convert';
import '../../../core/constants/api_constants.dart';

import 'package:http/http.dart' as http;

import '../../../core/storage_service.dart';
import '../models/account.dart';
import '../models/account_type.dart';

class AccountService {
  final String baseUrl = ApiConstants.baseUrl;

  final storageService = StorageService();

  Future<List<Account>> getAccounts() async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/accounts');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load accounts');
    }

    final List data = jsonDecode(response.body);

    return data.map((json) => Account.fromJson(json)).toList();
  }

  Future<Account> getAccountById(int id) async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/accounts/$id');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load account');
    }

    final data = jsonDecode(response.body);

    return Account.fromJson(data);
  }

  Future<Account> createAccount({
    required String name,
    required String description,
    required double initialBalance,
    String currency = 'DOP',
    int accountTypeId = 1,
    String? icon,
    String? color,
  }) async {
    final token = await storageService.getToken();
    final url = Uri.parse('$baseUrl/accounts');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'initialBalance': initialBalance,
        'currency': currency,
        'accountTypeId': accountTypeId,
        'icon': icon ?? 'bank',
        'color': color ?? '#10B981',
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? err['error'] ?? 'Error ${response.statusCode}');
      } catch (e) {
        if (e is Exception && !e.toString().startsWith('Exception: FormatException')) rethrow;
        throw Exception('Failed to create account (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body);
    return Account.fromJson(data);
  }

  Future<Account> updateAccount({
    required int id,
    required String name,
    required String description,
    String currency = 'DOP',
    int accountTypeId = 1,
    String? icon,
    String? color,
  }) async {
    final token = await storageService.getToken();
    final url = Uri.parse('$baseUrl/accounts/$id');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'currency': currency,
        'accountTypeId': accountTypeId,
        'icon': icon ?? 'bank',
        'color': color ?? '#10B981',
      }),
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? err['error'] ?? 'Error ${response.statusCode}');
      } catch (e) {
        if (e is Exception && !e.toString().startsWith('Exception: FormatException')) rethrow;
        throw Exception('Failed to update account (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body);
    return Account.fromJson(data);
  }

  Future<void> deleteAccount(int id) async {
    final token = await storageService.getToken();
    final url = Uri.parse('$baseUrl/accounts/$id');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account');
    }
  }

  Future<List<AccountType>> getAccountTypes() async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/account-types');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load account types');
    }

    final List data = jsonDecode(response.body);

    return data.map((json) => AccountType.fromJson(json)).toList();
  }
}
