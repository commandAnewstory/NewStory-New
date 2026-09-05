import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../core/api/dio_client.dart';
import '../../core/auth/auth_notifier.dart';

enum LoginStatus { idle, loading, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.idle, this.errorMessage});

  bool get isLoading => status == LoginStatus.loading;
}

class LoginNotifier extends StateNotifier<LoginState> {
  final Dio _dio;
  final AuthNotifier _auth;

  LoginNotifier(this._dio, this._auth) : super(const LoginState());

  Future<void> loginWithKakao() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      await _socialLogin('kakao', token.accessToken);
    } catch (e) {
      state = LoginState(
          status: LoginStatus.error, errorMessage: '카카오 로그인에 실패했습니다.');
    }
  }

  Future<void> loginWithGoogle() async {
    state = const LoginState(status: LoginStatus.loading);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = const LoginState(status: LoginStatus.idle);
        return;
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('idToken null');
      await _socialLogin('google', idToken);
    } catch (e) {
      state = LoginState(
          status: LoginStatus.error, errorMessage: '구글 로그인에 실패했습니다.');
    }
  }

  Future<void> _socialLogin(String provider, String token) async {
    final response = await _dio.post(
      '/api/auth/social/$provider',
      data: {'token': token},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    await _auth.login(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    state = const LoginState(status: LoginStatus.idle);
  }
}

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(
    ref.watch(dioProvider),
    ref.read(authProvider.notifier),
  ),
);
