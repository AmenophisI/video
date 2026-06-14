import 'package:local_auth/local_auth.dart';

class PrivateAccessAuthenticator {
  PrivateAccessAuthenticator({
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<bool> canAuthenticateWithDevice() async {
    try {
      return _localAuthentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithDevice() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      if (!supported) {
        return false;
      }

      return _localAuthentication.authenticate(
        localizedReason: 'プライベート動画を開くために認証してください',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
