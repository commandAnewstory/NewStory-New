import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/auth/auth_notifier.dart';
import 'package:newstory/core/widget/home_widget_platform.dart';
import 'package:newstory/core/widget/home_widget_service.dart';
import 'package:newstory/core/widget/home_widget_sync.dart';
import 'package:newstory/features/my/my_provider.dart';
import 'package:newstory/features/my/my_screen.dart';

import '../support/fake_api.dart';

class _MemoryStore implements WidgetStore {
  final Map<String, Object?> values = {};
  int redraws = 0;

  @override
  Future<T?> read<T>(String key) async => values[key] as T?;

  @override
  Future<void> save<T>(String key, T? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> redraw() async => redraws++;
}

class _RecordingScheduler implements WidgetScheduler {
  bool running = false;
  final List<String> calls = [];

  @override
  Future<void> start() async {
    running = true;
    calls.add('start');
  }

  @override
  Future<void> stop() async {
    running = false;
    calls.add('stop');
  }
}

Map<String, dynamic> _card(String title, [String time = '약 30초']) =>
    {'articleId': 1, 'title': title, 'convertedText': '• a', 'readingTimeLabel': time};

void main() {
  late FakeApi api;
  late _MemoryStore store;
  late _RecordingScheduler scheduler;
  late HomeWidgetService service;

  setUp(() {
    api = FakeApi();
    store = _MemoryStore();
    scheduler = _RecordingScheduler();
    service = HomeWidgetService(
      fetchCards: todayCardsFetcher(api.dio()),
      store: store,
      scheduler: scheduler,
    );
  });

  test('켜면 카드 최대 3개를 저장하고 주기 갱신을 시작한다', () async {
    api.onJson('GET', '/api/widget/today-cards',
        [_card('첫 기사'), _card('둘째 기사', '약 1분'), _card('셋째'), _card('넷째')]);

    await service.applyEnabled(true);

    expect(store.values[WidgetKeys.enabled], true);
    expect(store.values[WidgetKeys.state], WidgetStates.ok);
    expect(store.values[WidgetKeys.cardCount], 3);
    expect(store.values[WidgetKeys.title(0)], '첫 기사');
    expect(store.values[WidgetKeys.time(1)], '약 1분');
    expect(store.values[WidgetKeys.title(2)], '셋째');
    expect(store.values.containsKey(WidgetKeys.title(3)), isFalse);
    expect(scheduler.running, isTrue);
    expect(store.redraws, 1);
  });

  test('카드가 줄면 남는 칸은 비운다', () async {
    api.onJson('GET', '/api/widget/today-cards', [_card('a'), _card('b'), _card('c')]);
    await service.applyEnabled(true);
    api.onJson('GET', '/api/widget/today-cards', [_card('새 기사')]);

    await service.refresh();

    expect(store.values[WidgetKeys.title(0)], '새 기사');
    expect(store.values.containsKey(WidgetKeys.title(1)), isFalse);
    expect(store.values.containsKey(WidgetKeys.time(2)), isFalse);
    expect(store.values[WidgetKeys.cardCount], 1);
  });

  test('서버에 카드요약이 없으면 empty 상태', () async {
    api.onJson('GET', '/api/widget/today-cards', []);

    await service.applyEnabled(true);

    expect(store.values[WidgetKeys.state], WidgetStates.empty);
    expect(store.values[WidgetKeys.cardCount], 0);
  });

  test('끄면 disabled 상태 + 주기 갱신 중단, 서버는 부르지 않는다', () async {
    await service.applyEnabled(false);

    expect(store.values[WidgetKeys.enabled], false);
    expect(store.values[WidgetKeys.state], WidgetStates.disabled);
    expect(scheduler.calls, ['stop']);
    expect(api.calls('GET', '/api/widget/today-cards'), isEmpty);
    expect(store.redraws, 1);
  });

  test('refresh는 마지막 토글 값을 따른다 — 한 번도 안 켰으면 disabled', () async {
    final ok = await service.refresh();

    expect(ok, isTrue);
    expect(store.values[WidgetKeys.state], WidgetStates.disabled);
    expect(api.calls('GET', '/api/widget/today-cards'), isEmpty);
  });

  test('불러오기 실패하면 기존 카드를 지우지 않고 false (주기 작업 재시도)', () async {
    api.onJson('GET', '/api/widget/today-cards', [_card('어제 카드')]);
    await service.applyEnabled(true);
    api.on('GET', '/api/widget/today-cards', (_) => const FakeError(500));

    final ok = await service.refresh();

    expect(ok, isFalse);
    expect(store.values[WidgetKeys.state], WidgetStates.ok);
    expect(store.values[WidgetKeys.title(0)], '어제 카드');
  });

  group('MY 화면 토글 연동', () {
    Future<void> pumpMy(WidgetTester tester, {required bool serverEnabled}) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      api
        ..onJson('GET', '/api/users/me', {
          'id': 1,
          'email': 'me@newstory.test',
          'nickname': '예준',
          'widgetEnabled': serverEnabled,
          'lastGlossaryLevel': 'MEDIUM',
        })
        ..onJson('GET', '/api/widget/today-cards', [_card('오늘 카드')]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(api.dio()),
          homeWidgetServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: MyScreen()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('프로필을 불러오면 서버 토글 값이 위젯에 반영된다', (tester) async {
      await pumpMy(tester, serverEnabled: true);

      expect(store.values[WidgetKeys.enabled], true);
      expect(store.values[WidgetKeys.state], WidgetStates.ok);
      expect(scheduler.running, isTrue);
    });

    testWidgets('토글 저장 성공 시에만 위젯에 반영, 실패하면 그대로', (tester) async {
      await pumpMy(tester, serverEnabled: true);
      final container = ProviderScope.containerOf(tester.element(find.byType(MyScreen)));

      api.on('PATCH', '/api/users/me', (_) => const FakeError(500));
      await tester.runAsync(() => container.read(myProvider.notifier).setWidgetEnabled(false));
      expect(store.values[WidgetKeys.enabled], true, reason: '서버 저장 실패 → 위젯은 켜진 상태 유지');
      expect(container.read(myProvider).profile!.widgetEnabled, isTrue);

      api.onJson('PATCH', '/api/users/me', {'widgetEnabled': false});
      await tester.runAsync(() => container.read(myProvider.notifier).setWidgetEnabled(false));
      expect(store.values[WidgetKeys.enabled], false);
      expect(store.values[WidgetKeys.state], WidgetStates.disabled);
      expect(scheduler.running, isFalse);
    });
  });

  group('앱 시작 시 동기화', () {
    ProviderContainer build() => ProviderContainer(overrides: [
          dioProvider.overrideWithValue(api.dio()),
          homeWidgetServiceProvider.overrideWithValue(service),
        ]);

    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('로그인 상태면 서버 토글 값을 먼저 맞춘다 (재설치·다른 기기에서 켠 경우)', () async {
      api
        ..onJson('GET', '/api/users/me', {'id': 1, 'widgetEnabled': true})
        ..onJson('GET', '/api/widget/today-cards', [_card('오늘 카드')]);
      final container = build();
      await container.read(authProvider.notifier).login('a', 'r');

      await container.read(homeWidgetStartupSyncProvider)();

      expect(store.values[WidgetKeys.enabled], true);
      expect(store.values[WidgetKeys.title(0)], '오늘 카드');
      expect(scheduler.running, isTrue);
    });

    test('로그아웃 상태면 서버 프로필은 안 부르고 마지막 값으로 갱신', () async {
      store.values[WidgetKeys.enabled] = true;
      api.onJson('GET', '/api/widget/today-cards', []);
      final container = build();

      await container.read(homeWidgetStartupSyncProvider)();

      expect(api.calls('GET', '/api/users/me'), isEmpty);
      expect(store.values[WidgetKeys.state], WidgetStates.empty);
    });

    test('프로필 조회 실패하면 마지막 값으로 갱신', () async {
      api.on('GET', '/api/users/me', (_) => const FakeError(500));
      final container = build();
      await container.read(authProvider.notifier).login('a', 'r');

      await container.read(homeWidgetStartupSyncProvider)();

      expect(store.values[WidgetKeys.state], WidgetStates.disabled);
    });
  });
}
