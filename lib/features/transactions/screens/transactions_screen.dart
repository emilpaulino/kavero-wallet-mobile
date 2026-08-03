import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../accounts/models/account.dart';
import '../../accounts/services/account_service.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  final TextEditingController _searchController = TextEditingController();

  List<TransactionModel> _allTransactions = [];
  List<Account> _accounts = [];
  bool _isLoading = true;

  // Filter States
  String _searchQuery = '';
  String _selectedType = 'ALL'; // 'ALL', 'EXPENSE', 'INCOME'
  int? _selectedAccountId; // null = all accounts
  String _selectedPeriod = 'ALL'; // 'ALL', 'THIS_MONTH', 'LAST_MONTH'

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _transactionService.getTransactions();
      final accs = await _accountService.getAccounts();
      if (mounted) {
        setState(() {
          _allTransactions = txs;
          _accounts = accs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddTransactionScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  List<TransactionModel> get _filteredTransactions {
    return _allTransactions.where((t) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesDesc = t.description.toLowerCase().contains(q);
        final matchesCat = t.categoryName.toLowerCase().contains(q);
        final matchesAcc = t.accountName.toLowerCase().contains(q);
        if (!matchesDesc && !matchesCat && !matchesAcc) return false;
      }

      // 2. Type Filter
      if (_selectedType != 'ALL' && t.type != _selectedType) {
        return false;
      }

      // 3. Account Filter
      if (_selectedAccountId != null) {
        if (t.accountId != null) {
          if (t.accountId != _selectedAccountId) return false;
        } else {
          final acc = _accounts.firstWhere(
            (a) => a.id == _selectedAccountId,
            orElse: () => _accounts.first,
          );
          if (t.accountName.trim().toLowerCase() !=
              acc.name.trim().toLowerCase()) {
            return false;
          }
        }
      }

      // 4. Period Filter
      if (_selectedPeriod != 'ALL') {
        final now = DateTime.now();
        if (_selectedPeriod == 'THIS_MONTH') {
          if (t.date.year != now.year || t.date.month != now.month) {
            return false;
          }
        } else if (_selectedPeriod == 'LAST_MONTH') {
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final year = now.month == 1 ? now.year - 1 : now.year;
          if (t.date.year != year || t.date.month != lastMonth) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  double get _totalFilteredIncome => _filteredTransactions
      .where((t) => t.type == 'INCOME')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalFilteredExpenses => _filteredTransactions
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

  Map<String, List<TransactionModel>> _getGroupedTransactions(
      List<TransactionModel> txList) {
    final Map<String, List<TransactionModel>> groups = {};
    final sorted = List<TransactionModel>.from(txList)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final tx in sorted) {
      final key = _formatDateHeader(tx.date);
      groups.putIfAbsent(key, () => []).add(tx);
    }
    return groups;
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedType != 'ALL' ||
      _selectedAccountId != null ||
      _selectedPeriod != 'ALL';

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedType = 'ALL';
      _selectedAccountId = null;
      _selectedPeriod = 'ALL';
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerHeight = statusBarHeight + 70;
    final filteredList = _filteredTransactions;
    final groupedMap = _getGroupedTransactions(filteredList);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: Stack(
        children: [
          // Main Scrollable Content
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
                        120,
                      ),
                      children: [
                        // Search Bar
                        _SearchBar(
                          controller: _searchController,
                          onClear: () => _searchController.clear(),
                        ),

                        const SizedBox(height: 14),

                        // Segmented Type Selector (Todos / Gastos / Ingresos)
                        _TypeSegmentedFilter(
                          selectedType: _selectedType,
                          onTypeChanged: (type) =>
                              setState(() => _selectedType = type),
                        ),

                        const SizedBox(height: 10),

                        // Cuenta & Período Dropdown Filter Row
                        _DropdownFiltersRow(
                          selectedAccountId: _selectedAccountId,
                          selectedPeriod: _selectedPeriod,
                          accounts: _accounts,
                          hasActiveFilters: _hasActiveFilters,
                          onAccountChanged: (accId) =>
                              setState(() => _selectedAccountId = accId),
                          onPeriodChanged: (period) =>
                              setState(() => _selectedPeriod = period),
                          onClearFilters: _clearAllFilters,
                        ),

                        const SizedBox(height: 20),

                        // Stats Highlights Card
                        _FilteredStatsCard(
                          income: _totalFilteredIncome,
                          expenses: _totalFilteredExpenses,
                          count: filteredList.length,
                        ),

                        const SizedBox(height: 24),

                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historial de movimientos',
                              style: TextStyle(
                                color: AppColors.foreground(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${filteredList.length} ${filteredList.length == 1 ? 'resultado' : 'resultados'}',
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
                        if (filteredList.isEmpty)
                          _EmptyFilteredState(
                            hasActiveFilters: _hasActiveFilters,
                            onClearFilters: _clearAllFilters,
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedMap.entries.map((entry) {
                              final dateTitle = entry.key;
                              final txList = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header
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

                                  // Transaction Cards
                                  ...txList.map((tx) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _TransactionListItem(
                                        transaction: tx,
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

          // Glassmorphic Top Navigation Header
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
                        'MOVIMIENTOS',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 24,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openAddTransactionScreen,
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

// ─── Search Bar Component ─────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.foreground(context), fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Buscar por categoría, descripción...',
          hintStyle: TextStyle(
            color: AppColors.muted(context).withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary(context),
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.muted(context),
                    size: 20,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Type Segmented Filter Component ─────────────────────────────────────────

class _TypeSegmentedFilter extends StatelessWidget {
  final String selectedType; // 'ALL', 'EXPENSE', 'INCOME'
  final ValueChanged<String> onTypeChanged;

  const _TypeSegmentedFilter({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'Todos',
              isSelected: selectedType == 'ALL',
              activeColor: AppColors.primary(context),
              onTap: () => onTypeChanged('ALL'),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: 'Gastos',
              isSelected: selectedType == 'EXPENSE',
              activeColor: const Color(0xFFF43F5E),
              icon: Icons.arrow_downward_rounded,
              onTap: () => onTypeChanged('EXPENSE'),
            ),
          ),
          Expanded(
            child: _SegmentItem(
              label: 'Ingresos',
              isSelected: selectedType == 'INCOME',
              activeColor: const Color(0xFF10B981),
              icon: Icons.arrow_upward_rounded,
              onTap: () => onTypeChanged('INCOME'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final IconData? icon;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: activeColor, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : AppColors.muted(context),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? activeColor : AppColors.foreground(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown Filters Row Component (Cuenta & Período) ──────────────────────

class _DropdownFiltersRow extends StatelessWidget {
  final int? selectedAccountId;
  final String selectedPeriod;
  final List<Account> accounts;
  final bool hasActiveFilters;
  final ValueChanged<int?> onAccountChanged;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onClearFilters;

  const _DropdownFiltersRow({
    required this.selectedAccountId,
    required this.selectedPeriod,
    required this.accounts,
    required this.hasActiveFilters,
    required this.onAccountChanged,
    required this.onPeriodChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final String accountLabel = selectedAccountId == null
        ? 'Todas las cuentas'
        : accounts
            .firstWhere(
              (a) => a.id == selectedAccountId,
              orElse: () => accounts.first,
            )
            .name;

    final String periodLabel = selectedPeriod == 'ALL'
        ? 'Todas las fechas'
        : (selectedPeriod == 'THIS_MONTH' ? 'Este mes' : 'Mes anterior');

    return Row(
      children: [
        // Account Selector Dropdown Popup
        Expanded(
          child: PopupMenuButton<int?>(
            initialValue: selectedAccountId,
            color: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: onAccountChanged,
            itemBuilder: (ctx) => [
              PopupMenuItem<int?>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppColors.primary(context),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Todas las cuentas',
                      style: TextStyle(
                        color: AppColors.foreground(context),
                        fontWeight: selectedAccountId == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...accounts.map(
                (a) => PopupMenuItem<int?>(
                  value: a.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        size: 18,
                        color: AppColors.muted(context),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        a.name,
                        style: TextStyle(
                          color: AppColors.foreground(context),
                          fontWeight: selectedAccountId == a.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selectedAccountId != null
                    ? AppColors.primary(context).withValues(alpha: 0.12)
                    : AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedAccountId != null
                      ? AppColors.primary(context)
                      : AppColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 16,
                    color: selectedAccountId != null
                        ? AppColors.primary(context)
                        : AppColors.muted(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      accountLabel,
                      style: TextStyle(
                        color: selectedAccountId != null
                            ? AppColors.primary(context)
                            : AppColors.foreground(context),
                        fontSize: 12,
                        fontWeight: selectedAccountId != null
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: selectedAccountId != null
                        ? AppColors.primary(context)
                        : AppColors.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Period Selector Dropdown Popup
        Expanded(
          child: PopupMenuButton<String>(
            initialValue: selectedPeriod,
            color: AppColors.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: onPeriodChanged,
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'ALL',
                child: Text(
                  'Todas las fechas',
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontWeight: selectedPeriod == 'ALL'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'THIS_MONTH',
                child: Text(
                  'Este mes',
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontWeight: selectedPeriod == 'THIS_MONTH'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'LAST_MONTH',
                child: Text(
                  'Mes anterior',
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontWeight: selectedPeriod == 'LAST_MONTH'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selectedPeriod != 'ALL'
                    ? AppColors.primary(context).withValues(alpha: 0.12)
                    : AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedPeriod != 'ALL'
                      ? AppColors.primary(context)
                      : AppColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: selectedPeriod != 'ALL'
                        ? AppColors.primary(context)
                        : AppColors.muted(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      periodLabel,
                      style: TextStyle(
                        color: selectedPeriod != 'ALL'
                            ? AppColors.primary(context)
                            : AppColors.foreground(context),
                        fontSize: 12,
                        fontWeight: selectedPeriod != 'ALL'
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: selectedPeriod != 'ALL'
                        ? AppColors.primary(context)
                        : AppColors.muted(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (hasActiveFilters) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClearFilters,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF43F5E)),
              ),
              child: const Icon(
                Icons.filter_alt_off_rounded,
                color: Color(0xFFF43F5E),
                size: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Filtered Stats Card Component ────────────────────────────────────────────

class _FilteredStatsCard extends StatelessWidget {
  final double income;
  final double expenses;
  final int count;

  const _FilteredStatsCard({
    required this.income,
    required this.expenses,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ingresos',
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(income),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF43F5E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Color(0xFFF43F5E),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gastos',
                        style: TextStyle(
                          color: AppColors.muted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(expenses),
                    style: const TextStyle(
                      color: Color(0xFFF43F5E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction List Item Component ──────────────────────────────────────────

class _TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionListItem({required this.transaction});

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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Direction Icon Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.categoryName.isEmpty
                            ? (isExpense ? 'Gasto' : 'Ingreso')
                            : transaction.categoryName,
                        style: TextStyle(
                          color: AppColors.foreground(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        transaction.description.isEmpty
                            ? transaction.accountName
                            : '${transaction.description} • ${transaction.accountName}',
                        style: TextStyle(
                          color: AppColors.muted(context),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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
        ],
      ),
    );
  }
}

// ─── Empty Filtered State Component ───────────────────────────────────────────

class _EmptyFilteredState extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _EmptyFilteredState({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary(context),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? 'Sin resultados para la búsqueda'
                : 'Sin movimientos registrados',
            style: TextStyle(
              color: AppColors.foreground(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveFilters
                ? 'Intenta cambiar los filtros seleccionados o la palabra buscada.'
                : 'Registra tus ingresos y gastos para ver tu historial.',
            style: TextStyle(
              color: AppColors.muted(context),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onClearFilters,
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
