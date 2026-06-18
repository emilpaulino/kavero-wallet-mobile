import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/storage_service.dart';
import '../models/transaction.dart';
import '../../../core/constants/api_constants.dart';

class TransactionService {
  final String baseUrl = ApiConstants.baseUrl;

  final storageService = StorageService();

  Future<List<TransactionModel>> getTransactions() async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/transactions');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final List data = jsonDecode(response.body);

    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<void> createTransaction({
    required double amount,

    required String description,

    required String type,

    required int accountId,

    required int categoryId,
  }) async {
    final token = await storageService.getToken();

    final url = Uri.parse('$baseUrl/transactions');

    await http.post(
      url,

      headers: {
        'Content-Type': 'application/json',

        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'amount': amount,

        'description': description,

        'type': type,

        'accountId': accountId,

        'categoryId': categoryId,
      }),
    );
  }
}
