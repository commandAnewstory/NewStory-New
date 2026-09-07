import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/auth/auth_notifier.dart';

enum SignupStatus { idle, loading, error }

class SignupState {
  final SignupStatus status;
  final String? errorMessage;

  const SignupState({this.status = SignupStatus.idle, this.errorMessage});

  bool get isLoading => status == SignupStatus.loading;
}

class SignupNotifier extends StateNotifier<SignupState> {
  final Dio _dio;
  final AuthNotifier _auth;

  SignupNotifier(this._dio, this._auth) : super(const SignupState());

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
  }) async {
    if (email.isEmpty || password.isEmpty || nickname.isEmpty) {
      state = const SignupState(
          status: SignupStatus.error, errorMessage: '모든 항목을 입력해 주세요.');
      return;
    }
    if (password.length < 8) {
      state = const SignupState(
          status: SignupStatus.error, errorMessage: '비밀번호는 최소 8자 이상이어야 합니다.');
      return;
    }
    state = const SignupState(status: SignupStatus.loading);
    try {
      await _dio.post('/api/auth/signup', data: {
        'email': email,
        'password': password,
        'nickname': nickname,
      });
      // auto-login after signup
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      await _auth.login(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      state = const SignupState(status: SignupStatus.idle);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      state = SignupState(
          status: SignupStatus.error,
          errorMessage: msg ?? '가입에 실패했습니다. 다시 시도해 주세요.');
    } catch (_) {
      state = const SignupState(
          status: SignupStatus.error, errorMessage: '가입에 실패했습니다. 다시 시도해 주세요.');
    }
  }
}

final signupProvider =
    StateNotifierProvider.autoDispose<SignupNotifier, SignupState>(
  (ref) => SignupNotifier(
    ref.watch(dioProvider),
    ref.read(authProvider.notifier),
  ),
);
