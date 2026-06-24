import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/main_navigation_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    if (nameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await authService.register(
        name: nameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'No fue posible crear la cuenta';
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

  InputDecoration buildDecoration(
    BuildContext context,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.muted(context).withOpacity(0.7),
      ),
      filled: true,
      fillColor: AppColors.card(context),
      prefixIcon: Icon(
        icon,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

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
                'Crear cuenta',
                style: TextStyle(
                  color: AppColors.foreground(context),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Comienza a administrar tus finanzas',
                style: TextStyle(
                  color: AppColors.muted(context),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 32),

              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red[400],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              TextField(
                controller: nameController,
                decoration: buildDecoration(
                  context,
                  'Nombre',
                  Icons.person_outline,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: lastNameController,
                decoration: buildDecoration(
                  context,
                  'Apellido',
                  Icons.badge_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: buildDecoration(
                  context,
                  'ejemplo@correo.com',
                  Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: buildDecoration(
                  context,
                  'Contraseña',
                  Icons.lock_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: buildDecoration(
                  context,
                  'Confirmar contraseña',
                  Icons.lock_outline,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Crear cuenta',
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '¿Ya tienes una cuenta? Inicia sesión',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}