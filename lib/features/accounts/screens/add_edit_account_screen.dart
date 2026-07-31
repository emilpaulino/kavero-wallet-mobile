import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../models/account_type.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const AddEditAccountScreen({super.key, this.accountToEdit});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final AccountService accountService = AccountService();

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController balanceController;

  int? selectedAccountTypeId;
  Color selectedColor = const Color(0xFF0EA5E9);
  bool isLoading = false;

  List<AccountType> accountTypes = [];

  final List<Color> colorPalette = const [
    Color(0xFF0EA5E9), // Ocean Blue
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF59E0B), // Amber Gold
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF43F5E), // Rose Red
    Color(0xFF14B8A6), // Teal
    Color(0xFF6366F1), // Indigo
  ];

  bool get isEditing => widget.accountToEdit != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: isEditing ? widget.accountToEdit!.name : '',
    );
    descriptionController = TextEditingController(
      text: isEditing ? widget.accountToEdit!.description : '',
    );
    balanceController = TextEditingController(
      text: isEditing
          ? widget.accountToEdit!.currentBalance.toStringAsFixed(2)
          : '',
    );

    if (isEditing) {
      selectedAccountTypeId = widget.accountToEdit!.accountTypeId;
      selectedColor = _parseColor(widget.accountToEdit!.color);
    }

    nameController.addListener(() => setState(() {}));
    descriptionController.addListener(() => setState(() {}));
    balanceController.addListener(() => setState(() {}));
    _loadAccountTypes();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    balanceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountTypes() async {
    try {
      final types = await accountService.getAccountTypes();

      setState(() {
        accountTypes = types;

        if (types.isNotEmpty) {
          if (isEditing) {
            selectedAccountTypeId = widget.accountToEdit!.accountTypeId;
          } else {
            selectedAccountTypeId = types.first.id;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar los tipos de cuenta'),
          ),
        );
      }
    }
  }

  Color _parseColor(String colorStr) {
    if (colorStr.isNotEmpty && colorStr.startsWith('#')) {
      try {
        final buffer = StringBuffer();
        if (colorStr.length == 7) buffer.write('ff');
        buffer.write(colorStr.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (_) {}
    }
    return const Color(0xFF0EA5E9);
  }

  IconData _getTypeIcon(int? accountTypeId) {
    if (accountTypes.isEmpty || accountTypeId == null) {
      return Icons.account_balance_rounded;
    }

    final accountType = accountTypes.firstWhere(
      (type) => type.id == accountTypeId,
      orElse: () => accountTypes.first,
    );

    return _iconFromName(accountType.icon);
  }

  IconData _iconFromName(String icon) {
    switch (icon.toLowerCase()) {
      case 'payments':
        return Icons.payments_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance':
      default:
        return Icons.account_balance_rounded;
    }
  }

  Future<void> _handleSave() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final balanceText = balanceController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre de la cuenta'),
        ),
      );
      return;
    }

    if (selectedAccountTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de cuenta'),
        ),
      );
      return;
    }

    final double initialBalance = double.tryParse(balanceText) ?? 0.0;
    final hexColor =
        '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';

    setState(() => isLoading = true);

    try {
      if (isEditing) {
        await accountService.updateAccount(
          id: widget.accountToEdit!.id,
          name: name,
          description: description,
          accountTypeId: selectedAccountTypeId!,
          color: hexColor,
        );
      } else {
        await accountService.createAccount(
          name: name,
          description: description,
          initialBalance: initialBalance,
          accountTypeId: selectedAccountTypeId!,
          color: hexColor,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocurrió un error al guardar la cuenta: $errorMsg'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final String displayName = nameController.text.trim().isEmpty
        ? 'Nombre'
        : nameController.text.trim();
    final String displayDesc = descriptionController.text.trim().isEmpty
        ? 'Descripción corta'
        : descriptionController.text.trim();
    final double displayBalance =
        double.tryParse(balanceController.text.trim()) ??
        (isEditing ? widget.accountToEdit!.currentBalance : 0.0);

    final AccountType? selectedAccountType = accountTypes
        .cast<AccountType?>()
        .firstWhere(
          (type) => type?.id == selectedAccountTypeId,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, statusBarHeight + 74, 20, 40),
              children: [
                // Section Title
                const SizedBox(height: 10),

                // Live Preview Hero Card
                _LivePreviewCard(
                  name: displayName,
                  description: displayDesc,
                  balance: displayBalance,
                  typeLabel: selectedAccountType?.name ?? '',
                  accentColor: selectedColor,
                  iconData: _getTypeIcon(selectedAccountTypeId),
                ),

                const SizedBox(height: 28),

                // General Info Section
                const _SectionLabel(title: 'INFORMACIÓN DE LA CUENTA'),
                const SizedBox(height: 12),

                // Name Input
                _CustomTextField(
                  controller: nameController,
                  hintText: 'Ej. Efectivo',
                  labelText: 'Nombre de la cuenta',
                  icon: Icons.account_balance_rounded,
                ),

                const SizedBox(height: 16),

                // Description Input
                _CustomTextField(
                  controller: descriptionController,
                  hintText: 'Ej. Cuenta principal',
                  labelText: 'Descripción',
                  icon: Icons.notes_rounded,
                ),

                if (!isEditing) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel(title: 'BALANCE INICIAL'),
                  const SizedBox(height: 12),

                  // Initial Balance Input
                  _CustomTextField(
                    controller: balanceController,
                    hintText: '0.00',
                    labelText: 'Monto inicial disponible',
                    icon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixText: 'RD\$ ',
                  ),
                ],

                const SizedBox(height: 24),

                // Account Type Chips
                const _SectionLabel(title: 'TIPO DE CUENTA'),
                const SizedBox(height: 12),

                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: accountTypes.length,
                    itemBuilder: (ctx, i) {
                      final item = accountTypes[i];
                      final isSelected = selectedAccountTypeId == item.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => selectedAccountTypeId = item.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor
                                  : AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? selectedColor
                                    : AppColors.border(context),
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: selectedColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconFromName(item.icon),
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.muted(context),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.foreground(context),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Accent Color Selector
                const _SectionLabel(title: 'COLOR DE ACENTO'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colorPalette.map((c) {
                      final isSelected =
                          selectedColor.toARGB32() == c.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.foreground(context)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button at the end of scrollable content
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary(context).withValues(alpha: 0.35),
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
                    onPressed: isLoading ? null : _handleSave,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEditing ? Icons.check_rounded : Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEditing ? 'Guardar Cambios' : 'Crear Cuenta',
                                style: const TextStyle(
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

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 20, 12),
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
                        isEditing ? 'EDITAR CUENTA' : 'NUEVA CUENTA',
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 22,
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

// ─── Section Label Widget ──────────────────────────────────────────────────────

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

// ─── Live Hero Preview Card Widget ─────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  final String name;
  final String description;
  final double balance;
  final String typeLabel;
  final Color accentColor;
  final IconData iconData;

  const _LivePreviewCard({
    required this.name,
    required this.description,
    required this.balance,
    required this.typeLabel,
    required this.accentColor,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Squircle Icon
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
                child: Icon(iconData, color: Colors.white, size: 26),
              ),

              const SizedBox(width: 14),

              // Name & Desc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.foreground(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.muted(context),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Type Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 14),

          // Balance Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance disponible',
                style: TextStyle(
                  color: AppColors.muted(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                CurrencyFormatter.format(balance),
                style: TextStyle(
                  color: AppColors.foreground(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Custom Form TextField Widget ──────────────────────────────────────────────

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? prefixText;

  const _CustomTextField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.icon,
    this.keyboardType,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: AppColors.foreground(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.foreground(context), fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.muted(context).withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(icon, color: AppColors.primary(context), size: 20),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: AppColors.foreground(context),
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: AppColors.card(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: AppColors.primary(context),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
