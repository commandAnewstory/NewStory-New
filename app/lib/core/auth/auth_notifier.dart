import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyAccess = 'access_token';
const _keyRefresh = 'refresh_token';

final _storage = const FlutterSecureStorage();

class AuthState {
  final bool isLoggedIn;
  final String? accessToken;
  final String? refreshToken;

  const AuthState({
    required this.isLoggedIn,
    this.accessToken,
    this.refreshToken,
  });

  const AuthState.initial() : this(isLoggedIn: false);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> init() async {
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    if (access != null && refresh != null) {
      state = AuthState(
        isLoggedIn: true,
        accessToken: access,
        refreshToken: refresh,
      );
    }
  }

  Future<void> login(String accessToken, String refreshToken) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    await _storage.write(key: _keyRefresh, value: refreshToken);
    state = AuthState(
      isLoggedIn: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(key: _keyAccess, value: accessToken);
    state = AuthState(
      isLoggedIn: true,
      accessToken: accessToken,
      refreshToken: state.refreshToken,
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState.initial();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
