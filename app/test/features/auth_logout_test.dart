import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/core/auth/auth_notifier.dart';

void main() {
  late List<String> serverLogoutCalls;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    serverLogoutCalls = [];
  });

  ProviderContainer build({bool serverFails = false}) {
    return ProviderContainer(overrides: [
      logoutApiProvider.overrideWithValue((token) async {
        serverLogoutCalls.add(token);
        if (serverFails) throw Exception('offline');
      }),
    ]);
  }

  test('로그아웃하면 서버에 refresh 토큰 폐기를 요청하고 기기 토큰도 지운다', () async {
    container = build();
    final auth = container.read(authProvider.notifier);
    await auth.login('access-1', 'refresh-1');

    await auth.logout();

    expect(serverLogoutCalls, ['refresh-1']);
    expect(container.read(authProvider).isLoggedIn, isFalse);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('서버 호출이 실패해도 기기 로그아웃은 된다', () async {
    container = build(serverFails: true);
    final auth = container.read(authProvider.notifier);
    await auth.login('access-1', 'refresh-1');

    await auth.logout();

    expect(container.read(authProvider).isLoggedIn, isFalse);
  });

  test('토큰이 이미 무효라서 로그아웃시킬 땐 서버를 부르지 않는다', () async {
    container = build();
    final auth = container.read(authProvider.notifier);
    await auth.login('access-1', 'refresh-1');

    await auth.logout(notifyServer: false);

    expect(serverLogoutCalls, isEmpty);
    expect(container.read(authProvider).isLoggedIn, isFalse);
  });
}
