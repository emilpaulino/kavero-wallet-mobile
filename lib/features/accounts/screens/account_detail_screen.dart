import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/services/transaction_service.dart';
import 'add_edit_account_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final AccountService _accountService = AccountService();
  final TransactionService _transactionService = TransactionService();

  late Account _currentAccount;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _currentAccount = widget.account;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Reload updated accounts to ensure fresh state
      final accounts = await _accountService.getAccounts();
      final freshAccount = accounts.firstWhere(
        (a) => a.id == _currentAccount.id,
        orElse: () => _currentAccount,
      );

      // Load all transactions and filter for this account
      final allTransactions = await _transactionService.getTransactions();
      final accountTxList = allTransactions.where((t) {
        if (t.accountId != null && t.accountId == freshAccount.id) {
          return true;
        }
        return t.accountName.trim().toLowerCase() ==
            freshAccount.name.trim().toLowerCase();
      }).toList();

      if (mounted) {
        setState(() {
          _currentAccount = freshAccount;
          _transactions = accountTxList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getAccountColor(Account account) {
    if (account.color.isNotEmpty && account.color.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (account.color.length == 7) buffer.write('ff');
        buffer.write(account.color.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (_) {}
    }

    final nameLower = account.name.toLowerCase();
    final typeLower = account.accountTypeName.toLowerCase();
    final descLower = account.description.toLowerCase();

    if (nameLower.contains('efectivo') ||
        typeLower.contains('cash') ||
        descLower.contains('disponible')) {
      return const Color(0xFF10B981);
    } else if (nameLower.contains('ahorro') ||
        typeLower.contains('saving') ||
        descLower.contains('emergencia')) {
      return const Color(0xFFF59E0B);
    } else if (nameLower.contains('tarjeta') ||
        typeLower.contains('credit') ||
        descLower.contains('crédito')) {
      return const Color(0xFFF43F5E);
    } else if (nameLower.contains('banreservas') ||
        nameLower.contains('banco') ||
        typeLower.contains('bank')) {
      return const Color(0xFF0EA5E9);
    } else if (nameLower.contains('inversion') || nameLower.contains('fondo')) {
      return const Color(0xFF8B5CF6);
    }

    return const Color(0xFF0EA5E9);
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

  Future<void> _openEditAccount() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAccountScreen(accountToEdit: _currentAccount),
      ),
    );

    if (updated == true) {
      await _loadData();
    }
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == 'INCOME')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpenses => _transactions
      .where((t) => t.type == 'EXPENSE')
      .fold(0.0, (sum, t) => sum + t.amount);

  String _formatDateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(d.year, d.month, d.day);

    if (txDate.isAtSameMomentAs(today)) {
      return 'Hoy';
    } else if (txDate.isAtSameMomentAs(yesterday)) {
      return 'Ayer';
    }

    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    final monthName = months[d.month - 1];
    if (d.year == now.year) {
      return '${d.day} de $monthName';
    }
    return '${d.day} de $monthName, ${d.year}';
  }

  Map<String, List<TransactionModel>> get _groupedTransactions {
    final Map<String, List<TransactionModel>> groups = {};
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final tx in sorted) {
      final key = _formatDateHeader(tx.date);
      groups.putIfAbsent(key, () => []).add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 70;
    final Color accentColor = _getAccountColor(_currentAccount);
    final IconData iconData = _getAccountIcon(_currentAccount);
    final groupedMap = _groupedTransactions;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary(context),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        headerHeight + 12,
                        20,
                        40,
                      ),
                      children: [
                        // Account Hero Detail Card
                        _AccountHeroCard(
                          account: _currentAccount,
                          accentColor: accentColor,
                          iconData: iconData,
                          hideBalance: _hideBalance,
                          onToggleVisibility: () =>
                              setState(() => _hideBalance = !_hideBalance),
                        ),

                        const SizedBox(height: 24),

                        // Stats Summary Row
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Ingresos',
                                amount: _totalIncome,
                                isExpense: false,
                                hideBalance: _hideBalance,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatBox(
                                label: 'Gastos',
                                amount: _totalExpenses,
                                isExpense: true,
                                hideBalance: _hideBalance,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transacciones',
                              style: TextStyle(
                                color: AppColors.foreground(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_transactions.length} ${_transactions.length == 1 ? 'movimiento' : 'movimientos'}',
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Grouped Transactions List or Empty State
                        if (_transactions.isEmpty)
                          _EmptyTransactionsState()
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedMap.entries.map((entry) {
                              final dateTitle = entry.key;
                              final txList = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Group Header
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 10,
                                      left: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: AppColors.primary(context),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateTitle,
                                          style: TextStyle(
                                            color: AppColors.foreground(
                                              context,
                                            ),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Transaction Cards under date group
                                  ...txList.map((tx) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _AccountTransactionTile(
                                        transaction: tx,
                                        hideBalance: _hideBalance,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context, true),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.foreground(context),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'DETALLE DE CUENTA',
                            style: TextStyle(
                              color: AppColors.primary(context),
                              fontSize: 18,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Top Right Pencil Edit Button
                      GestureDetector(
                        onTap: _openEditAccount,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary(context),
                                AppColors.primaryDark(context),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary(
                                  context,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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

// ─── Account Hero Card Component ──────────────────────────────────────────────

class _AccountHeroCard extends StatelessWidget {
  final Account account;
  final Color accentColor;
  final IconData iconData;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;

  const _AccountHeroCard({
    required this.account,
    required this.accentColor,
    required this.iconData,
    required this.hideBalance,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(iconData, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        color: AppColors.foreground(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        account.accountTypeName.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.primary(context),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          if (account.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              account.description,
              style: TextStyle(
                color: AppColors.muted(context),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, thickness: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE ACTUAL',
                    style: TextStyle(
                      color: AppColors.muted(context),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hideBalance
                        ? '••••••••'
                        : CurrencyFormatter.format(account.currentBalance),
                    style: TextStyle(
                      color: AppColors.foreground(context),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.border(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  account.currency.isEmpty ? 'DOP' : account.currency,
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Box Component ────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final bool isExpense;
  final bool hideBalance;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.isExpense,
    required this.hideBalance,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final icon = isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hideBalance ? '••••' : CurrencyFormatter.format(amount),
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Tile Component ────────────────────────────────────────────────

class _AccountTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool hideBalance;

  const _AccountTransactionTile({
    required this.transaction,
    required this.hideBalance,
  });

  bool get isExpense => transaction.type == 'EXPENSE';

  String _formatTime(DateTime d) {
    final hourNum = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final minuteStr = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$hourNum:$minuteStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final Color bgColor = color.withValues(alpha: 0.12);
    final IconData iconData = isExpense
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryName.isEmpty
                      ? (isExpense ? 'Gasto' : 'Ingreso')
                      : transaction.categoryName,
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (transaction.description.isNotEmpty) ...[
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _formatTime(transaction.date),
                      style: TextStyle(
                        color: AppColors.muted(context).withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            hideBalance
                ? '••••'
                : '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State Component ─────────────────────────────────────────────────────

class _EmptyTransactionsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary(context),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin transacciones',
            style: TextStyle(
              color: AppColors.foreground(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay transacciones registradas para esta cuenta.',
            style: TextStyle(
              color: AppColors.muted(context),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
