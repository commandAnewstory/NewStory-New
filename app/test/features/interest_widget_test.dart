import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/widget/home_widget_platform.dart';
import 'package:newstory/core/widget/home_widget_service.dart';
import 'package:newstory/core/widget/home_widget_sync.dart';
import 'package:newstory/core/auth/auth_notifier.dart';
import 'package:newstory/features/article/article_detail_screen.dart';
import 'package:newstory/features/my/my_screen.dart';
import 'package:newstory/main.dart';

import '../support/fake_api.dart';

class _MemoryStore implements WidgetStore {
  final Map<String, Object?> values = {};

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
  Future<void> redraw() async {}
}

class _NoScheduler implements WidgetScheduler {
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

class _FakeLaunch implements WidgetLaunchSource {
  final Uri? first;
  final controller = StreamController<Uri?>.broadcast();
  _FakeLaunch(this.first);

  @override
  Future<Uri?> initial() async => first;
  @override
  Stream<Uri?> get clicks => controller.stream;
}

Map<String, dynamic> _profile({bool widget = true, List<String> interests = const []}) => {
      'id': 1,
      'email': 'me@newstory.test',
      'nickname': '예준',
      'widgetEnabled': widget,
      'lastGlossaryLevel': 'LOW',
      'interestCategories': interests,
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late _MemoryStore store;
  late HomeWidgetService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    api = FakeApi()
      ..onJson('GET', '/api/widget/popular', [
        {'articleId': 7, 'title': '금리 동결', 'category': '경제'},
      ]);
    store = _MemoryStore();
    service = HomeWidgetService(
        fetchNews: popularNewsFetcher(api.dio()), store: store, scheduler: _NoScheduler());
  });

  group('위젯 링크 → 앱 화면', () {
    test('기사 카드요약 링크를 기사 상세 경로로 바꾼다', () {
      expect(widgetUriToLocation(Uri.parse('newstory://article/7?style=card')),
          '/home/article/7?style=card');
      expect(widgetUriToLocation(Uri.parse('newstory://article/7')), '/home/article/7');
    });

    test('모르는 링크·잘못된 id·이상한 스타일은 무시 또는 스타일만 버림', () {
      expect(widgetUriToLocation(null), isNull);
      expect(widgetUriToLocation(Uri.parse('https://evil.example/article/7')), isNull);
      expect(widgetUriToLocation(Uri.parse('newstory://article/abc?style=card')), isNull);
      expect(widgetUriToLocation(Uri.parse('newstory://article/7/8')), isNull);
      expect(widgetUriToLocation(Uri.parse('newstory://article/7?style=x')), '/home/article/7');
    });
  });

  group('위젯 데이터', () {
    test('저장된 관심 카테고리로 popular를 부르고 id·제목·카테고리를 저장', () async {
      await service.applyProfile(enabled: true, categories: ['경제', 'IT']);

      final call = api.calls('GET', '/api/widget/popular').single;
      expect(call.queryParameters['categories'], '경제,IT');
      expect(store.values[WidgetKeys.categories], '경제,IT');
      expect(store.values[WidgetKeys.title(0)], '금리 동결');
      expect(store.values[WidgetKeys.badge(0)], '경제');
      expect(store.values[WidgetKeys.articleId(0)], '7');
    });

    test('관심 카테고리가 없으면 categories 없이(전체) 부른다', () async {
      await service.applyProfile(enabled: true, categories: []);
      expect(api.calls('GET', '/api/widget/popular').single.queryParameters.containsKey('categories'),
          isFalse);
    });

    test('백그라운드 갱신(refresh)도 저장된 카테고리를 쓴다', () async {
      await service.applyProfile(enabled: true, categories: ['스포츠']);
      await service.refresh();
      expect(api.calls('GET', '/api/widget/popular').last.queryParameters['categories'], '스포츠');
    });

    test('카테고리만 바꾸면 위젯이 꺼져 있을 땐 서버를 안 부른다', () async {
      await service.applyProfile(enabled: false, categories: []);
      await service.applyCategories(['문화']);
      expect(api.calls('GET', '/api/widget/popular'), isEmpty);
      expect(store.values[WidgetKeys.categories], '문화');
    });

    test('앱 시작 동기화가 서버 관심 카테고리를 위젯에 반영', () async {
      api.onJson('GET', '/api/users/me', _profile(interests: ['IT']));
      final container = ProviderContainer(overrides: [
        dioProvider.overrideWithValue(api.dio()),
        homeWidgetServiceProvider.overrideWithValue(service),
      ]);
      await container.read(authProvider.notifier).login('a', 'r');

      await container.read(homeWidgetStartupSyncProvider)();

      expect(store.values[WidgetKeys.categories], 'IT');
      expect(api.calls('GET', '/api/widget/popular').last.queryParameters['categories'], 'IT');
    });
  });

  group('MY 관심 카테고리', () {
    Future<void> pumpMy(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(api.dio()),
          homeWidgetServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: MyScreen()),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('칩을 누르면 서버에 저장하고 위젯도 그 카테고리로 갱신', (tester) async {
      api
        ..onJson('GET', '/api/users/me', _profile(interests: ['정치']))
        ..onJson('PATCH', '/api/users/me', _profile(interests: ['정치', 'IT']));
      await pumpMy(tester);
      expect(find.text('1개 선택'), findsOneWidget);

      await tester.tap(find.byKey(const Key('interest-IT')));
      await tester.pumpAndSettle();

      final patch = api.calls('PATCH', '/api/users/me').single;
      expect((patch.data as Map)['interestCategories'], ['정치', 'IT']);
      expect(find.text('2개 선택'), findsOneWidget);
      expect(store.values[WidgetKeys.categories], '정치,IT');
    });

    testWidgets('선택된 칩을 다시 누르면 빠지고, 다 빼면 전체 안내', (tester) async {
      api
        ..onJson('GET', '/api/users/me', _profile(interests: ['정치']))
        ..onJson('PATCH', '/api/users/me', _profile());
      await pumpMy(tester);

      await tester.tap(find.byKey(const Key('interest-정치')));
      await tester.pumpAndSettle();

      expect((api.calls('PATCH', '/api/users/me').single.data as Map)['interestCategories'], []);
      expect(find.text('안 고르면 전체 카테고리에서 골라요'), findsOneWidget);
    });

    testWidgets('저장 실패하면 원래대로 + 스낵바', (tester) async {
      api
        ..onJson('GET', '/api/users/me', _profile(interests: ['정치']))
        ..on('PATCH', '/api/users/me', (_) => const FakeError(500));
      await pumpMy(tester);

      await tester.tap(find.byKey(const Key('interest-IT')));
      await tester.pumpAndSettle();

      expect(find.text('1개 선택'), findsOneWidget);
      expect(find.text('관심 카테고리를 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    });
  });

  group('위젯에서 기사 누르기', () {
    void stubArticle() {
      api
        ..onJson('GET', '/api/news/7', {
          'id': 7,
          'title': '금리 동결',
          'url': 'https://news.example.com/7',
          'category': '경제',
          'publishedAt': '2026-10-18T09:00:00',
        })
        ..onJson('GET', '/api/users/me', _profile())
        ..onJson('GET', '/api/convert/original', {'title': '금리 동결', 'content': '원문 본문'})
        ..onJson('POST', '/api/news/7/view', null)
        ..onJson('POST', '/api/convert', {
          'id': 21,
          'convertedText': '- 기준금리 동결\n- 물가 부담',
          'glossary': [],
          'bookmarked': false,
        });
    }

    testWidgets('카드요약 탭으로 열리고 난이도 안 묻고 사용자 기본 난이도로 바로 생성', (tester) async {
      stubArticle();
      await tester.pumpWidget(ProviderScope(
        overrides: [dioProvider.overrideWithValue(api.dio())],
        child: const MaterialApp(home: ArticleDetailScreen(articleId: 7, initialStyle: 'card')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('변환 시작'), findsNothing);
      final convert = api.calls('POST', '/api/convert').single;
      expect((convert.data as Map)['style'], 'card');
      expect((convert.data as Map)['level'], 'LOW');
      expect(find.textContaining('기준금리 동결', findRichText: true), findsOneWidget);
    });

    testWidgets('로그아웃 상태로 위젯을 눌러 켜면 로그인 화면', (tester) async {
      final launch = _FakeLaunch(Uri.parse('newstory://article/7?style=card'));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(api.dio()),
          widgetLaunchSourceProvider.overrideWithValue(launch),
        ],
        child: const NewStoryApp(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('로그인'), findsWidgets);
      expect(api.calls('POST', '/api/convert'), isEmpty);
    });

    testWidgets('로그인 상태에서 앱이 켜져 있을 때 위젯을 누르면 기사 카드요약으로 이동', (tester) async {
      stubArticle();
      api.onJson('GET', '/api/news', {'content': [], 'totalPages': 1});
      final launch = _FakeLaunch(null);
      final container = ProviderContainer(overrides: [
        dioProvider.overrideWithValue(api.dio()),
        widgetLaunchSourceProvider.overrideWithValue(launch),
      ]);
      addTearDown(container.dispose);
      await container.read(authProvider.notifier).login('a', 'r');
      await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: const NewStoryApp()));
      await tester.pumpAndSettle();

      launch.controller.add(Uri.parse('newstory://article/7?style=card'));
      await tester.pumpAndSettle();

      expect(find.byType(ArticleDetailScreen), findsOneWidget);
      expect((api.calls('POST', '/api/convert').single.data as Map)['style'], 'card');
    });
  });
}
