import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import 'account_detail_screen.dart';
import 'add_edit_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService accountService = AccountService();
  List<Account> accounts = [];
  bool isLoading = true;
  bool _hideBalance = false;

  double get totalBalance =>
      accounts.fold(0, (sum, a) => sum + a.currentBalance);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      final list = await accountService.getAccounts();
      if (mounted) {
        setState(() {
          accounts = list;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color _getAccountColor(Account account, int index) {
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

    final List<Color> palette = [
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFF43F5E),
      const Color(0xFF14B8A6),
    ];
    return palette[index % palette.length];
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

  Future<void> _openAddEditAccountScreen({Account? accountToEdit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAccountScreen(accountToEdit: accountToEdit),
      ),
    );

    if (result == true) {
      await loadAccounts();
    }
  }

  Future<void> _openAccountDetailScreen(Account account) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountDetailScreen(account: account),
      ),
    );

    if (result == true) {
      await loadAccounts();
    }
  }

  Future<void> _confirmDeleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Eliminar cuenta',
          style: TextStyle(
            color: AppColors.foreground(ctx),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${account.name}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.muted(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.muted(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await accountService.deleteAccount(account.id);
        await loadAccounts();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar la cuenta')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 70;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      headerHeight + 12,
                      20,
                      120,
                    ),
                    children: [
                      // Total Balance Highlighted Green Card
                      _TotalBalanceCard(
                        totalBalance: totalBalance,
                        hideBalance: _hideBalance,
                        onToggleVisibility: () =>
                            setState(() => _hideBalance = !_hideBalance),
                      ),

                      const SizedBox(height: 32),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tus cuentas',
                            style: TextStyle(
                              color: AppColors.foreground(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${accounts.length} ${accounts.length == 1 ? 'cuenta' : 'cuentas'}',
                            style: TextStyle(
                              color: AppColors.muted(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Accounts List
                      if (accounts.isEmpty)
                        _EmptyAccountsState(
                          onAddTap: () => _openAddEditAccountScreen(),
                        )
                      else
                        Column(
                          children: List.generate(accounts.length, (index) {
                            final account = accounts[index];
                            final accentColor = _getAccountColor(
                              account,
                              index,
                            );
                            final icon = _getAccountIcon(account);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _AccountItemCard(
                                account: account,
                                accentColor: accentColor,
                                iconData: icon,
                                hideBalance: _hideBalance,
                                onTap: () => _openAccountDetailScreen(account),
                                onEdit: () => _openAddEditAccountScreen(
                                  accountToEdit: account,
                                ),
                                onDelete: () => _confirmDeleteAccount(account),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    statusBarHeight + 12,
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
                      Text(
                        'MIS CUENTAS',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 25,
                          letterSpacing: 4,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openAddEditAccountScreen(),
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
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
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

// ─── Total Balance Green Highlighted Card ──────────────────────────────────────

class _TotalBalanceCard extends StatelessWidget {
  final double totalBalance;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;

  const _TotalBalanceCard({
    required this.totalBalance,
    required this.hideBalance,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(context).withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Balance total',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onToggleVisibility,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            hideBalance ? '••••••••' : CurrencyFormatter.format(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual Account Card ───────────────────────────────────────────────────

class _AccountItemCard extends StatelessWidget {
  final Account account;
  final Color accentColor;
  final IconData iconData;
  final bool hideBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountItemCard({
    required this.account,
    required this.accentColor,
    required this.iconData,
    required this.hideBalance,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Account Accent Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(iconData, color: Colors.white, size: 24),
                    ),

                    const SizedBox(width: 14),

                    // Name and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: TextStyle(
                              color: AppColors.foreground(context),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (account.description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              account.description,
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Three dots PopupMenuButton
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.muted(context),
                        size: 22,
                      ),
                      color: AppColors.card(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: AppColors.primary(context),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Editar',
                                style: TextStyle(
                                  color: AppColors.foreground(context),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 18,
                                color: Color(0xFFF43F5E),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: Color(0xFFF43F5E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: AppColors.border(context)),
                const SizedBox(height: 14),

                // Bottom Balance Alignment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      hideBalance
                          ? '••••••••'
                          : CurrencyFormatter.format(account.currentBalance),
                      style: TextStyle(
                        color: AppColors.foreground(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────

class _EmptyAccountsState extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyAccountsState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary(context),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes cuentas registradas',
            style: TextStyle(
              color: AppColors.foreground(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Añade tu primera cuenta para organizar tus finanzas.',
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: onAddTap,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Añadir cuenta',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
