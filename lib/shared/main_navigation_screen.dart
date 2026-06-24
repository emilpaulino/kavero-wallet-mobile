import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/home/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  Widget _getScreen() {
    switch (currentIndex) {
      case 0:
        return const HomeScreen();

      case 1:
        return const Scaffold(
          body: Center(
            child: Text(
              'Transactions',
              style: TextStyle(fontSize: 30),
            ),
          ),
        );

      case 2:
        return const Scaffold(
          body: Center(
            child: Text(
              'Accounts',
              style: TextStyle(fontSize: 30),
            ),
          ),
        );

      case 3:
        return const ProfileScreen();

      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,

      body: _getScreen(),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.card(context).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      selected: currentIndex == 0,
                      onTap: () => setState(() => currentIndex = 0),
                    ),

                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      selected: currentIndex == 1,
                      onTap: () => setState(() => currentIndex = 1),
                    ),

                    _NavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      selected: currentIndex == 2,
                      onTap: () => setState(() => currentIndex = 2),
                    ),

                    _NavItem(
                      icon: Icons.person_rounded,
                      selected: currentIndex == 3,
                      onTap: () => setState(() => currentIndex = 3),
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
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary(context).withOpacity(0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected
              ? AppColors.primary(context)
              : AppColors.muted(context),
        ),
      ),
    );
  }
}