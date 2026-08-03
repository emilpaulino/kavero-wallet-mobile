import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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
  List<Account> accounts = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    amountController.addListener(() => setState(() {}));
    descriptionController.addListener(() => setState(() {}));
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
    try {
      final result = await categoryService.getCategories(type);
      if (mounted) {
        setState(() {
          categories = result;
          if (result.isNotEmpty) {
            selectedCategoryId = result.first.id;
          } else {
            selectedCategoryId = null;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> loadAccounts() async {
    try {
      final result = await accountService.getAccounts();
      if (mounted) {
        setState(() {
          accounts = result;
          if (result.isNotEmpty && selectedAccountId == null) {
            selectedAccountId = result.first.id;
          }
        });
      }
    } catch (_) {}
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.muted(context).withValues(alpha: 0.5),
        fontSize: 15,
      ),
      filled: true,
      fillColor: AppColors.card(context),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.border(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
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

    setState(() => isLoading = true);

    try {
      await transactionService.createTransaction(
        amount: double.parse(amountText),
        description: descriptionController.text.trim(),
        type: type,
        accountId: selectedAccountId!,
        categoryId: selectedCategoryId!,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar la transacción')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  IconData _getAccountIcon(Account account) {
    final nameLower = account.name.toLowerCase();
    final typeLower = account.accountTypeName.toLowerCase();

    if (nameLower.contains('efectivo') || typeLower.contains('cash')) {
      return Icons.payments_rounded;
    } else if (nameLower.contains('ahorro') || typeLower.contains('savings')) {
      return Icons.savings_rounded;
    } else if (nameLower.contains('tarjeta') || typeLower.contains('credit')) {
      return Icons.credit_card_rounded;
    } else if (nameLower.contains('banreservas') ||
        nameLower.contains('banco') ||
        typeLower.contains('bank')) {
      return Icons.account_balance_rounded;
    } else if (nameLower.contains('inversion') || nameLower.contains('fondo')) {
      return Icons.trending_up_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 70;

    final double enteredAmount =
        double.tryParse(amountController.text.trim()) ?? 0.0;
    final String descriptionText = descriptionController.text.trim();

    final Account? selectedAccount = accounts
        .cast<Account?>()
        .firstWhere((a) => a?.id == selectedAccountId, orElse: () => null);

    final Category? selectedCategory = categories
        .cast<Category?>()
        .firstWhere((c) => c?.id == selectedCategoryId, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: Stack(
        children: [
          // Form Content
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                headerHeight + 12,
                20,
                40,
              ),
              children: [
                // Live Transaction Preview Hero Card
                _LiveTransactionPreviewCard(
                  type: type,
                  amount: enteredAmount,
                  description: descriptionText,
                  accountName: selectedAccount?.name ?? 'Sin cuenta',
                  categoryName: selectedCategory?.name ?? 'Sin categoría',
                ),

                const SizedBox(height: 28),

                // Transaction Type Selector
                const _SectionLabel(title: 'TIPO DE TRANSACCIÓN'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TypeSelectorTile(
                        label: 'Gasto',
                        iconData: Icons.arrow_downward_rounded,
                        isSelected: type == 'EXPENSE',
                        activeColor: const Color(0xFFF43F5E),
                        onTap: () async {
                          if (type != 'EXPENSE') {
                            setState(() => type = 'EXPENSE');
                            await loadCategories();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeSelectorTile(
                        label: 'Ingreso',
                        iconData: Icons.arrow_upward_rounded,
                        isSelected: type == 'INCOME',
                        activeColor: const Color(0xFF10B981),
                        onTap: () async {
                          if (type != 'INCOME') {
                            setState(() => type = 'INCOME');
                            await loadCategories();
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Amount & Description Section
                const _SectionLabel(title: 'MONTO Y DESCRIPCIÓN'),
                const SizedBox(height: 12),

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
                      padding: const EdgeInsets.only(left: 18, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RD\$',
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

                const SizedBox(height: 14),

                // Description Input
                TextField(
                  controller: descriptionController,
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontSize: 15,
                  ),
                  decoration: _inputDecoration(
                    context: context,
                    hintText: 'Descripción de la transacción (opcional)',
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.muted(context),
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Account Selection Section
                const _SectionLabel(title: 'SELECCIONA CUENTA'),
                const SizedBox(height: 12),
                accounts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Text(
                          'Cargando cuentas disponibles...',
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: accounts.map((account) {
                            final isSelected =
                                selectedAccountId == account.id;
                            final icon = _getAccountIcon(account);

                            return GestureDetector(
                              onTap: () => setState(
                                () => selectedAccountId = account.id,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary(context)
                                          .withValues(alpha: 0.12)
                                      : AppColors.card(context),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary(context)
                                        : AppColors.border(context),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary(context)
                                            : AppColors.border(context)
                                                .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.muted(context),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
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

                // Category Selection Section
                const _SectionLabel(title: 'CATEGORÍA'),
                const SizedBox(height: 12),
                categories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border(context)),
                        ),
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
                          final isSelected =
                              selectedCategoryId == category.id;

                          return GestureDetector(
                            onTap: () => setState(
                              () => selectedCategoryId = category.id,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary(context)
                                        .withValues(alpha: 0.12)
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
                                    Icons.grid_view_rounded,
                                    color: isSelected
                                        ? AppColors.primary(context)
                                        : AppColors.muted(context),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: AppColors.foreground(context),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                const SizedBox(height: 36),

                // Save Action Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary(context)
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : handleSave,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Guardar Transacción',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Glassmorphic Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    statusBarHeight + 8,
                    20,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context).withValues(alpha: 0.75),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.foreground(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NUEVA TRANSACCIÓN',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 20,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label Helper ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.muted(context),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Live Preview Hero Card Component ──────────────────────────────────────────

class _LiveTransactionPreviewCard extends StatelessWidget {
  final String type;
  final double amount;
  final String description;
  final String accountName;
  final String categoryName;

  const _LiveTransactionPreviewCard({
    required this.type,
    required this.amount,
    required this.description,
    required this.accountName,
    required this.categoryName,
  });

  bool get isExpense => type == 'EXPENSE';

  @override
  Widget build(BuildContext context) {
    final Color accentColor =
        isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final IconData iconData = isExpense
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(iconData, color: accentColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isExpense ? 'GASTO' : 'INGRESO',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Account Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.muted(context),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      accountName,
                      style: TextStyle(
                        color: AppColors.foreground(context),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'MONTO REGISTRADO',
            style: TextStyle(
              color: AppColors.muted(context),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: accentColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primary(context),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    categoryName,
                    style: TextStyle(
                      color: AppColors.foreground(context),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty)
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Type Selector Tile Component ──────────────────────────────────────────────

class _TypeSelectorTile extends StatelessWidget {
  final String label;
  final IconData iconData;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeSelectorTile({
    required this.label,
    required this.iconData,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: isSelected ? activeColor : AppColors.muted(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.foreground(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
