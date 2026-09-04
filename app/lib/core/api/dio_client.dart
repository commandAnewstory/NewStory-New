import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';

const _baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://localhost:8090');

Dio buildDio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(dio, ref));
  return dio;
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio, this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authProvider).accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = _ref.read(authProvider).refreshToken;
        if (refreshToken == null) {
          await _ref.read(authProvider.notifier).logout();
          handler.next(err);
          return;
        }

        final response = await _dio.post('/api/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': null}));

        final newAccessToken =
            (response.data as Map<String, dynamic>)['data']['accessToken']
                as String;
        await _ref
            .read(authProvider.notifier)
            .updateAccessToken(newAccessToken);

        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _ref.read(authProvider.notifier).logout();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

final dioProvider = Provider<Dio>((ref) => buildDio(ref));
