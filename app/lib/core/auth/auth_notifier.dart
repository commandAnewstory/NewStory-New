import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyAccess = 'access_token';
const _keyRefresh = 'refresh_token';

final _storage = const FlutterSecureStorage();

const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://172.28.37.20:8090');

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

  /// [notifyServer]가 true면 서버의 refresh 토큰도 폐기한다. 서버 호출이 실패해도(오프라인 등)
  /// 기기 로그아웃은 진행한다. 토큰이 이미 무효라 로그아웃시키는 경우(401 처리)엔 false.
  Future<void> logout({bool notifyServer = true}) async {
    final refreshToken = state.refreshToken;
    if (notifyServer && refreshToken != null) {
      try {
        await ref.read(logoutApiProvider)(refreshToken);
      } catch (_) {}
    }
    await _storage.deleteAll();
    state = const AuthState.initial();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

typedef LogoutApi = Future<void> Function(String refreshToken);

/// 인증 헤더 없는 별도 Dio로 호출한다 — dioProvider는 authProvider를 읽으므로 순환 의존을 피하려는 것.
/// 로그아웃 API는 공개 엔드포인트라 토큰 헤더가 필요 없다.
final logoutApiProvider = Provider<LogoutApi>((ref) {
  return (refreshToken) async {
    final dio = Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    await dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
  };
});
