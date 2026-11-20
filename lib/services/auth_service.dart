import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

enum BiometricAuthStatus {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  canceled,
  error,
}

class BiometricAuthResult {
  final BiometricAuthStatus status;
  final String? message;

  const BiometricAuthResult(this.status, {this.message});

  bool get isSuccess => status == BiometricAuthStatus.success;
}

class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    final result = await authenticateWithDetails();
    return result.isSuccess;
  }

  Future<BiometricAuthResult> authenticateWithDetails() async {
    try {
      if (!await isAvailable) {
        return const BiometricAuthResult(
          BiometricAuthStatus.notAvailable,
          message: 'Biometrics are not supported on this device.',
        );
      }
      final success = await auth.authenticate(
        localizedReason: 'Please authenticate to access your loans',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (success) {
        return const BiometricAuthResult(BiometricAuthStatus.success);
      } else {
        return const BiometricAuthResult(
          BiometricAuthStatus.canceled,
          message: 'Authentication was canceled.',
        );
      }
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return const BiometricAuthResult(
            BiometricAuthStatus.notEnrolled,
            message: 'Biometrics not set up on this device. Please use your PIN.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricAuthResult(
            BiometricAuthStatus.lockedOut,
            message: 'Biometrics locked out. Please use your PIN.',
          );
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const BiometricAuthResult(
            BiometricAuthStatus.notAvailable,
            message: 'Biometrics unavailable.',
          );
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          return const BiometricAuthResult(
            BiometricAuthStatus.canceled,
            message: 'Authentication canceled.',
          );
        default:
          return BiometricAuthResult(
            BiometricAuthStatus.error,
            message: e.description ?? 'Biometric authentication failed.',
          );
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          BiometricAuthStatus.notEnrolled,
          message: 'Biometrics not set up on this device. Please use your PIN.',
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          BiometricAuthStatus.lockedOut,
          message: 'Biometrics locked out. Please use your PIN.',
        );
      }
      return BiometricAuthResult(
        BiometricAuthStatus.error,
        message: e.message ?? 'Biometric authentication failed.',
      );
    } catch (e) {
      return BiometricAuthResult(
        BiometricAuthStatus.error,
        message: e.toString(),
      );
    }
  }
}
