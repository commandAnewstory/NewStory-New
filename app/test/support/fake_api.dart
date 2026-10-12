import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 테스트용 가짜 서버. 실제 네트워크 대신 `메서드 + 경로`별로 정해둔 응답을 돌려주고, 들어온 요청을 기록한다.
class FakeApi implements HttpClientAdapter {
  final Map<String, Object? Function(RequestOptions)> _routes = {};
  final List<RequestOptions> requests = [];

  /// [body]가 [FakeError]면 그 상태코드로 실패시킨다.
  void on(String method, String path, Object? Function(RequestOptions req) body) {
    _routes['${method.toUpperCase()} $path'] = body;
  }

  void onJson(String method, String path, Object? data) =>
      on(method, path, (_) => {'success': true, 'data': data});

  List<RequestOptions> calls(String method, String path) => requests
      .where((r) => r.method == method.toUpperCase() && r.path == path)
      .toList();

  Dio dio() => Dio(BaseOptions(baseUrl: 'http://fake'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final handler = _routes['${options.method} ${options.path}'];
    if (handler == null) {
      return ResponseBody.fromString('{"success":false}', 404,
          headers: _jsonHeaders);
    }
    final body = handler(options);
    if (body is FakeError) {
      return ResponseBody.fromString('{"success":false}', body.status,
          headers: _jsonHeaders);
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: _jsonHeaders);
  }

  static const _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}

class FakeError {
  final int status;
  const FakeError(this.status);
}
