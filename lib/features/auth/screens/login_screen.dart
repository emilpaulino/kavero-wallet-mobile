import 'package:flutter/material.dart';
import 'package:kavero_wallet_mobile/features/auth/screens/register_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/services/local_auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final storageService = StorageService();
  final localAuthService = LocalAuthService();

  bool showBiometricLogin = false;
  BiometricType? biometricType;

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadBiometrics();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Correo o contraseña incorrectos';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loginWithBiometrics() async {
    final authenticated = await localAuthService.authenticate();

    if (!mounted) return;

    if (authenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    }
  }

  Future<void> loadBiometrics() async {
    final token = await storageService.getToken();
    final enabled = await storageService.isBiometricsEnabled();

    if (!mounted) return;

    setState(() {
      showBiometricLogin = token != null && enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Top Brand
              Text(
                'KAVERO',
                style: TextStyle(
                  color: AppColors.primary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bienvenido',
                style: TextStyle(
                  color: AppColors.foreground(context),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(color: AppColors.muted(context), fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Error Banner
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Email Input
              Text(
                'Email',
                style: TextStyle(
                  color: AppColors.foreground(context).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.foreground(context)),
                decoration: InputDecoration(
                  hintText: 'ejemplo@correo.com',
                  hintStyle: TextStyle(
                    color: AppColors.muted(context).withOpacity(0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.card(context),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.muted(context),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.border(context),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.primary(context),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 24),

              // Password Input
              Text(
                'Contraseña',
                style: TextStyle(
                  color: AppColors.foreground(context).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: AppColors.foreground(context)),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(
                    color: AppColors.muted(context).withOpacity(0.7),
                  ),
                  filled: true,
                  fillColor: AppColors.card(context),
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    color: AppColors.muted(context),
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.border(context),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.primary(context),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
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
                  onPressed: isLoading ? null : handleLogin,
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
                          'Ingresar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              if (showBiometricLogin) ...[
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: loginWithBiometrics,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: BorderSide(
                        color: AppColors.border(context),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Platform.isIOS
                            ? SvgPicture.asset(
                          'assets/icons/face_id.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            AppColors.foreground(context),
                            BlendMode.srcIn,
                          ),
                        )
                            : const Icon(Icons.fingerprint),

                        const SizedBox(width: 12),

                        Text(
                          Platform.isIOS
                              ? 'Ingresar con Face ID'
                              : 'Ingresar con huella digital',
                          style: TextStyle(
                            color: AppColors.foreground(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('¿No tienes una cuenta? Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
