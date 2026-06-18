import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../categories/models/category.dart';
import '../../categories/services/category_service.dart';
import '../services/transaction_service.dart';
import '../../accounts/models/account.dart';
import '../../accounts/services/account_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryService = CategoryService();
  final accountService = AccountService();
  final transactionService = TransactionService();

  String type = 'EXPENSE';
  int? selectedAccountId;
  int? selectedCategoryId;
  List<Category> categories = [];
  bool isLoading = false;

  List<Account> accounts = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadAccounts();
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadCategories() async {
    final result = await categoryService.getCategories(type);

    setState(() {
      categories = result;
      selectedCategoryId = null;
    });
  }

  Future<void> loadAccounts() async {
    final result = await accountService.getAccounts();

    setState(() {
      accounts = result;
    });
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.6)),
      filled: true,
      fillColor: AppColors.card(context),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.border(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.primary(context), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Future<void> handleSave() async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto válido')),
      );
      return;
    }
    if (selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta')),
      );
      return;
    }
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await transactionService.createTransaction(
        amount: double.parse(amountText),
        description: descriptionController.text.trim(),
        type: type,
        accountId: selectedAccountId!,
        categoryId: selectedCategoryId!,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la transacción')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.foreground(context)),
        title: Text(
          'Nueva Transacción',
          style: TextStyle(
            color: AppColors.foreground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Label
            Text(
              'Monto',
              style: TextStyle(
                color: AppColors.foreground(context).withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: AppColors.foreground(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              decoration: _inputDecoration(
                context: context,
                hintText: '0.00',
                prefixIcon: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 20),
                      Text(
                        r'RD$',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description Label
            Text(
              'Descripción',
              style: TextStyle(
                color: AppColors.foreground(context).withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            // Description Input
            TextField(
              controller: descriptionController,
              style: TextStyle(color: AppColors.foreground(context)),
              decoration: _inputDecoration(
                context: context,
                hintText: '¿En qué consistió esta transacción?',
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: AppColors.muted(context),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Type Label
            Text(
              'Tipo de Transacción',
              style: TextStyle(
                color: AppColors.foreground(context).withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Transaction Type Segmented Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        type = 'EXPENSE';
                      });

                      await loadCategories();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: type == 'EXPENSE'
                            ? const Color(0xFFFF4D6A).withOpacity(0.1)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: type == 'EXPENSE'
                              ? const Color(0xFFFF4D6A)
                              : AppColors.border(context),
                          width: type == 'EXPENSE' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            color: type == 'EXPENSE'
                                ? const Color(0xFFFF4D6A)
                                : AppColors.muted(context),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gasto',
                            style: TextStyle(
                              color: type == 'EXPENSE'
                                  ? const Color(0xFFFF4D6A)
                                  : AppColors.foreground(context),
                              fontWeight: type == 'EXPENSE'
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        type = 'INCOME';
                      });

                      await loadCategories();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: type == 'INCOME'
                            ? const Color(0xFF0EA5E9).withOpacity(0.1)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: type == 'INCOME'
                              ? const Color(0xFF0EA5E9)
                              : AppColors.border(context),
                          width: type == 'INCOME' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            color: type == 'INCOME'
                                ? const Color(0xFF0EA5E9)
                                : AppColors.muted(context),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingreso',
                            style: TextStyle(
                              color: type == 'INCOME'
                                  ? const Color(0xFF0EA5E9)
                                  : AppColors.foreground(context),
                              fontWeight: type == 'INCOME'
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Account Label
            Text(
              'Cuenta',
              style: TextStyle(
                color: AppColors.foreground(context).withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Account Horizontal Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: accounts.map((account) {
                  final isSelected = selectedAccountId == account.id;
                  return GestureDetector(
                    onTap: () => setState(() => selectedAccountId = account.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary(context).withOpacity(0.1)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary(context)
                              : AppColors.border(context),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: isSelected
                                ? AppColors.primary(context)
                                : AppColors.muted(context),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            account.name,
                            style: TextStyle(
                              color: AppColors.foreground(context),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Category Label
            Text(
              'Categoría',
              style: TextStyle(
                color: AppColors.foreground(context).withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Category Horizontal Chips
            categories.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Cargando categorías...',
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 14,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((category) {
                      final isSelected = selectedCategoryId == category.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category.id;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary(context).withOpacity(0.1)
                                : AppColors.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : AppColors.border(context),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: isSelected
                                    ? AppColors.primary(context)
                                    : AppColors.muted(context),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: AppColors.foreground(context),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 48),

            // Save Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary(context),
                    AppColors.primaryDark(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary(context).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Guardar Transacción',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
