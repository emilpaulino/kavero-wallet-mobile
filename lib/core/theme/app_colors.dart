import 'package:flutter/material.dart';

class AppColors {

  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D0D14)
          : const Color(0xFFF5F7FA);

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF16151F)
          : Colors.white;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF059669)
          : const Color(0xFF10B981);

  static Color primaryDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF047857)
          : const Color(0xFF059669);

  static Color foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF0EEFF)
          : const Color(0xFF111827);

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF7A7595)
          : const Color(0xFF6B7280);

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? primary(context).withOpacity(0.12)
          : const Color(0x14000000);
}