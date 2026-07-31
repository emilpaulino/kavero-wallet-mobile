import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../accounts/models/account.dart';
import '../accounts/services/account_service.dart';
import '../transactions/models/transaction.dart';
import '../transactions/services/transaction_service.dart';
import '../auth/screens/login_screen.dart';
import '../transactions/screens/add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAccounts;

  const HomeScreen({super.key, this.onNavigateToAccounts});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final accountService = AccountService();
  final transactionService = TransactionService();

  List<Account> accounts = [];
  List<TransactionModel> transactions = [];
  bool isLoading = true;

  double get totalBalance =>
      accounts.fold(0, (sum, a) => sum + a.currentBalance);

  double get totalIncome => transactions
      .where((t) => t.type == 'INCOME')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == 'EXPENSE')
      .fold(0, (sum, t) => sum + t.amount);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    loadData();
  }

  Future<void> loadData() async {
    try {
      final a = await accountService.getAccounts();
      final t = await transactionService.getTransactions();
      setState(() {
        accounts = a;
        transactions = t;
        isLoading = false;
      });
    } catch (_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen bg = ${AppColors.bg(context)}");
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
            await loadData();
          },
          backgroundColor: AppColors.bg(context),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: 56,
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
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            )
          : _HomeBody(
              accounts: accounts,
              transactions: transactions,
              totalBalance: totalBalance,
              totalIncome: totalIncome,
              totalExpenses: totalExpenses,
              onNavigateToAccounts: widget.onNavigateToAccounts,
            ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final List<Account> accounts;
  final List<TransactionModel> transactions;
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final VoidCallback? onNavigateToAccounts;

  const _HomeBody({
    required this.accounts,
    required this.transactions,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    this.onNavigateToAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 70;

    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, headerHeight + 12, 20, 120),
            children: [
              _BalanceCard(
                balance: totalBalance,
                income: totalIncome,
                expenses: totalExpenses,
              ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Cuentas',
                onSeeAll: () {
                  if (onNavigateToAccounts != null) {
                    onNavigateToAccounts!();
                  }
                },
              ),
              const SizedBox(height: 14),
              accounts.isEmpty
                  ? _EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No hay cuentas',
                      subtitle: 'Crea tu primera cuenta',
                    )
                  : Column(
                      children: accounts
                          .take(3)
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AccountTile(account: a),
                            ),
                          )
                          .toList(),
                    ),
              const SizedBox(height: 32),
              _SectionHeader(title: 'Últimas transacciones', onSeeAll: () {}),
              const SizedBox(height: 14),
              transactions.isEmpty
                  ? _EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin transacciones',
                      subtitle: 'Empieza a registrar tus finanzas',
                    )
                  : SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: transactions.length > 5
                            ? 5
                            : transactions.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _TransactionCard(transaction: transactions[i]),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 12),
                decoration: BoxDecoration(
                  color: AppColors.bg(context).withOpacity(0.70),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border(context),
                      width: 1,
                    ),
                  ),
                ),
                child: _Header(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'KAVERO',
          style: TextStyle(
            color: AppColors.primary(context),
            fontSize: 25,
            letterSpacing: 4,
          ),
        ),
        Row(children: [_IconBtn(icon: Icons.notifications_none_rounded)]),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;

  const _IconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary(context), size: 20),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatefulWidget {
  final double balance;
  final double income;
  final double expenses;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _hidden = false;

  String _fmt(double n) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    ).format(n);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(context).withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance Total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _hidden = !_hidden),
                    child: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white60,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _hidden ? '••••••' : _fmt(widget.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'Ingresos',
                      value: _hidden ? '••••' : _fmt(widget.income),
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF38BDF8),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  Expanded(
                    child: _BalanceStat(
                      label: 'Gastos',
                      value: _hidden ? '••••' : _fmt(widget.expenses),
                      icon: Icons.trending_down_rounded,
                      iconColor: const Color(0xFFFCA5A5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.foreground(context),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                'Ver todas',
                style: TextStyle(
                  color: AppColors.primary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                color: AppColors.primary(context),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Account Tile ─────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

  IconData get _icon {
    final nameLower = account.name.toLowerCase();
    final typeLower = account.accountTypeName.toLowerCase();

    if (nameLower.contains('efectivo') || typeLower.contains('efectivo') || typeLower.contains('cash')) {
      return Icons.payments_rounded;
    } else if (nameLower.contains('ahorro') || typeLower.contains('ahorro') || typeLower.contains('savings')) {
      return Icons.savings_rounded;
    } else if (nameLower.contains('tarjeta') || typeLower.contains('tarjeta') || typeLower.contains('credit')) {
      return Icons.credit_card_rounded;
    } else if (nameLower.contains('banreservas') || nameLower.contains('banco') || typeLower.contains('banco') || typeLower.contains('bank')) {
      return Icons.account_balance_rounded;
    } else if (nameLower.contains('inversion') || typeLower.contains('inversión') || typeLower.contains('fondo')) {
      return Icons.trending_up_rounded;
    }
    return Icons.account_balance_wallet_rounded;
  }

  Color _getAccountColor(BuildContext context) {
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
    if (nameLower.contains('efectivo') || typeLower.contains('efectivo') || typeLower.contains('cash')) {
      return const Color(0xFF10B981);
    } else if (nameLower.contains('ahorro') || typeLower.contains('ahorro') || typeLower.contains('savings')) {
      return const Color(0xFFF59E0B);
    } else if (nameLower.contains('tarjeta') || typeLower.contains('tarjeta') || typeLower.contains('credit')) {
      return const Color(0xFFF43F5E);
    } else if (nameLower.contains('banreservas') || nameLower.contains('banco') || typeLower.contains('banco') || typeLower.contains('bank')) {
      return const Color(0xFF0EA5E9);
    } else if (nameLower.contains('inversion') || typeLower.contains('inversión')) {
      return const Color(0xFF8B5CF6);
    }
    return AppColors.primary(context);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccountColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(_icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.description.isEmpty
                      ? account.accountTypeName
                      : account.description,
                  style: TextStyle(
                    color: AppColors.muted(context),
                    fontSize: 13,
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

// ─── Transaction Card ─────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionCard({required this.transaction});

  bool get isExpense => transaction.type == 'EXPENSE';

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? const Color(0xFFFF4D6A) : const Color(0xFF0EA5E9);
    final bgColor = isExpense
        ? const Color(0xFFFF4D6A).withOpacity(0.12)
        : const Color(0xFF0EA5E9).withOpacity(0.12);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isExpense
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            transaction.categoryName,
            style: TextStyle(
              color: AppColors.foreground(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            transaction.description,
            style: TextStyle(color: AppColors.muted(context), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  CurrencyFormatter.format(transaction.amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary(context).withOpacity(0.25),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary(context), size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppColors.foreground(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
