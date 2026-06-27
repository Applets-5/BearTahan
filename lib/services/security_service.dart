import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      debugPrint('Biometrics not supported on Web via local_auth.');
      return false;
    }
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      debugPrint(
        'Biometric availability: canCheck=$canAuthenticateWithBiometrics, isSupported=${await _auth.isDeviceSupported()}',
      );
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      debugPrint('Starting biometric authentication...');
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access Parent Mode',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      debugPrint('Biometric authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(
        'PlatformException during biometric authentication: ${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  bool verifyPin(String inputPin, String? storedPin) {
    if (storedPin == null || storedPin.isEmpty) {
      // If no PIN is set, we could either allow any or force set.
      // For now, let's assume '0000' is the default if not set.
      return inputPin == '0000';
    }
    return inputPin == storedPin;
  }
}
