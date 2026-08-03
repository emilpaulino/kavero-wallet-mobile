import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/accounts/screens/accounts_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/transactions/screens/transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<double>? _scaleAnim;

  void _initAnimations() {
    if (_animController != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    final CurvedAnimation curve = CurvedAnimation(
      parent: controller,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(curve);
    _animController = controller;

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (currentIndex == index) return;
    setState(() {
      currentIndex = index;
    });
    _animController?.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    _initAnimations();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim!,
        child: ScaleTransition(
          scale: _scaleAnim!,
          child: IndexedStack(
            index: currentIndex,
            children: [
              HomeScreen(
                onNavigateToAccounts: () => _onTabTapped(2),
              ),
              const TransactionsScreen(),
              const AccountsScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 14,
                sigmaY: 14,
              ),
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.card(context).withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Inicio',
                      selected: currentIndex == 0,
                      onTap: () => _onTabTapped(0),
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Movimientos',
                      selected: currentIndex == 1,
                      onTap: () => _onTabTapped(1),
                    ),
                    _NavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Cuentas',
                      selected: currentIndex == 2,
                      onTap: () => _onTabTapped(2),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Perfil',
                      selected: currentIndex == 3,
                      onTap: () => _onTabTapped(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary(context);
    final inactiveColor = AppColors.muted(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              AnimatedOpacity(
                opacity: selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                child: Text(
                  label,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}