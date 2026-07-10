import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/local_auth_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/screens/login_screen.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService profileService = ProfileService();
  final StorageService storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? profile;
  bool isLoading = true;
  bool biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await profileService.getProfile();

      if (mounted) {
        final enabled = await storageService.isBiometricsEnabled();

        setState(() {
          profile = result;
          biometricsEnabled = enabled;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    Future<void> logout() async {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> showEditProfileModal() async {
    final nameController = TextEditingController(text: profile?.name ?? '');

    final lastNameController = TextEditingController(
      text: profile?.lastName ?? '',
    );

    bool isSaving = false;
    String? selectedPhoto = profile?.profilePhoto;
    String? modalErrorMessage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar perfil',
                    style: TextStyle(
                      color: AppColors.foreground(context),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (modalErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        modalErrorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Tomar foto'),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final image = await _imagePicker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 70,
                                    );

                                    if (image == null) return;

                                    final bytes = await image.readAsBytes();

                                    setModalState(() {
                                      selectedPhoto = base64Encode(bytes);
                                    });
                                  },
                                ),

                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Elegir de la galería'),
                                  onTap: () async {
                                    Navigator.pop(context);

                                    final image = await _imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 70,
                                    );

                                    if (image == null) return;

                                    final bytes = await image.readAsBytes();

                                    setModalState(() {
                                      selectedPhoto = base64Encode(bytes);
                                    });
                                  },
                                ),

                                if (selectedPhoto != null)
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text(
                                      'Quitar foto',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);

                                      setModalState(() {
                                        selectedPhoto = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: selectedPhoto != null
                              ? MemoryImage(base64Decode(selectedPhoto!))
                              : null,
                          child: selectedPhoto == null
                              ? Text(
                            profile!.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),

                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.card(context),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() {
                                isSaving = true;
                                modalErrorMessage = null;
                              });

                              try {
                                final updatedProfile = await profileService.updateProfile(
                                  name: nameController.text.trim(),
                                  lastName: lastNameController.text.trim(),
                                  profilePhoto: selectedPhoto,
                                );

                                if (!mounted) return;

                                setState(() {
                                  profile = updatedProfile;
                                });

                                Navigator.pop(context);
                              } catch (e) {
                                String message = 'No se pudo actualizar el perfil';
                                if (e is Exception) {
                                  message = e.toString().replaceAll('Exception: ', '');
                                }
                                setModalState(() {
                                  modalErrorMessage = message;
                                });
                              } finally {
                                setModalState(() {
                                  isSaving = false;
                                });
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget buildOptionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Icon(
          icon,
          color: danger ? Colors.red : AppColors.primary(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: danger ? Colors.red : AppColors.foreground(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: danger ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> showChangePasswordModal() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isSaving = false;
    String? modalErrorMessage;

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      color: AppColors.foreground(context),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (modalErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        modalErrorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                        setModalState(() {
                          isSaving = true;
                        });

                        try {
                          setModalState(() {
                            modalErrorMessage = null;
                          });

                          await profileService.changePassword(
                            currentPassword:
                            currentPasswordController.text.trim(),
                            newPassword:
                            newPasswordController.text.trim(),
                            confirmPassword:
                            confirmPasswordController.text.trim(),
                          );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contraseña actualizada correctamente',
                              ),
                            ),
                          );
                        } catch (e) {
                          String message = 'No se pudo cambiar la contraseña';
                          if (e is Exception) {
                            message = e.toString().replaceAll('Exception: ', '');
                          }
                          setModalState(() {
                            modalErrorMessage = message;
                          });
                        } finally {
                          setModalState(() {
                            isSaving = false;
                          });
                        }
                      },
                      child: isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: const Center(child: Text('No es posible cargar el perfil')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            Text(
              'Perfil',
              style: TextStyle(
                color: AppColors.foreground(context),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF10B981),
                    Color(0xFF34D399),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: showEditProfileModal,
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white24,
                          backgroundImage: profile!.profilePhoto != null
                              ? MemoryImage(base64Decode(profile!.profilePhoto!))
                              : null,
                          child: profile!.profilePhoto == null
                              ? Text(
                            profile!.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          '${profile!.name} ${profile!.lastName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          profile!.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            buildSectionTitle('Preferencias'),

            buildOptionCard(
              icon: Icons.attach_money,
              title: 'Moneda preferida',
              subtitle: profile!.preferredCurrency,
            ),

            const SizedBox(height: 12),

            buildSectionTitle('Seguridad'),

            buildOptionCard(
              icon: Icons.lock_outline,
              title: 'Cambiar contraseña',
              onTap: showChangePasswordModal,
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint,
                  color: AppColors.primary(context),
                ),
                title: Text(
                  'Autenticación Biométrica',
                  style: TextStyle(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Usar biometría para iniciar sesión',
                ),
                value: biometricsEnabled,
                onChanged: (value) async {
                  final localAuth = LocalAuthService();

                  if (value) {
                    final authenticated = await localAuth.authenticate();

                    if (authenticated) {
                      await storageService.saveBiometricsEnabled(true);

                      setState(() {
                        biometricsEnabled = true;
                      });

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Autenticación biométrica activada'),
                        ),
                      );
                    }
                  } else {
                    await storageService.clearBiometrics();

                    setState(() {
                      biometricsEnabled = false;
                    });

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Autenticación biométrica desactivada'),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            buildSectionTitle('Acerca de'),

            buildOptionCard(
              icon: Icons.info_outline,
              title: 'Versión',
              subtitle: '1.0.0',
            ),

            const SizedBox(height: 24),

            buildOptionCard(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              danger: true,
              onTap: logout,
            ),
          ],
        ),
      ),
    );
  }
}
