import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();

      print("isDeviceSupported: $isSupported");
      print("canCheckBiometrics: $canCheck");
      print("availableBiometrics: $available");

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a Kavero Wallet',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      print("authenticated: $authenticated");

      return authenticated;
    } catch (e, s) {
      print(e);
      print(s);
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }
}
