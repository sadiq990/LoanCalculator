import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!await isAvailable) return false;
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access your loans',
      );
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
