import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/home/article_repository.dart';
import 'package:newstory/features/home/home_screen.dart';
import 'package:newstory/features/search/search_provider.dart';
import 'package:newstory/features/search/search_screen.dart';

import '../support/fake_api.dart';

Map<String, dynamic> _article(int id, String title, {String category = '정치'}) => {
      'id': id,
      'title': title,
      'url': 'https://a.example/$id',
      'source': '테스트일보',
      'category': category,
      'publishedAt': '2026-10-16T10:00:00',
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> content, {int totalPages = 1}) =>
    {'content': content, 'totalPages': totalPages};

void main() {
  late FakeApi api;

  setUp(() => api = FakeApi());

  group('SearchNotifier', () {
    late ProviderContainer container;
    late SearchNotifier notifier;

    setUp(() {
      container = ProviderContainer(overrides: [
        searchProvider.overrideWith((ref) => SearchNotifier(
              ArticleRepository(api.dio()),
              debounce: const Duration(milliseconds: 20),
            )),
      ]);
      container.listen(searchProvider, (_, _) {});
      notifier = container.read(searchProvider.notifier);
    });

    tearDown(() => container.dispose());

    // 디바운스(20ms)보다 넉넉히 — 전체 테스트를 병렬로 돌려 CPU가 바쁠 때도 안 흔들리게
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 250));

    test('연속 입력하면 멈춘 뒤 마지막 검색어로 한 번만 요청', () async {
      api.onJson('GET', '/api/news', _page([_article(1, '금리 인상')]));

      notifier.setQuery('금');
      notifier.setQuery('금리');
      notifier.setQuery('금리 ');
      await settle();

      final calls = api.calls('GET', '/api/news');
      expect(calls, hasLength(1));
      expect(calls.single.queryParameters['keyword'], '금리');
      expect(calls.single.queryParameters.containsKey('category'), isFalse);
      expect(container.read(searchProvider).status, SearchStatus.loaded);
      expect(container.read(searchProvider).articles.single.title, '금리 인상');
    });

    test('빈 검색어는 요청하지 않고 idle', () async {
      notifier.setQuery('   ');
      await settle();

      expect(api.calls('GET', '/api/news'), isEmpty);
      expect(container.read(searchProvider).status, SearchStatus.idle);
    });

    test('카테고리를 바꾸면 기다리지 않고 category를 같이 보내 다시 검색', () async {
      api.onJson('GET', '/api/news', _page([]));
      notifier.setQuery('정치');
      await settle();

      notifier.setCategory('경제');
      // 디바운스(20ms)보다 짧게만 기다려도 요청이 나가 있어야 함
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final last = api.calls('GET', '/api/news').last;
      expect(api.calls('GET', '/api/news'), hasLength(2));
      expect(last.queryParameters['category'], '경제');
      expect(last.queryParameters['keyword'], '정치');
    });

    test('검색어 없을 때 카테고리만 바꾸면 요청 안 함', () async {
      notifier.setCategory('IT');
      await settle();
      expect(api.calls('GET', '/api/news'), isEmpty);
    });

    test('늦게 도착한 이전 검색 응답은 무시', () async {
      final slow = Completer<Object?>();
      api.on('GET', '/api/news', (req) {
        if (req.queryParameters['keyword'] == '옛날') return slow.future;
        return {'success': true, 'data': _page([_article(2, '최신 결과')])};
      });

      notifier.setQuery('옛날');
      await settle();
      notifier.setQuery('최신');
      await settle();
      slow.complete({'success': true, 'data': _page([_article(1, '옛날 결과')])});
      await settle();

      expect(container.read(searchProvider).articles.single.title, '최신 결과');
    });

    test('다음 페이지를 이어 붙인다', () async {
      api.on('GET', '/api/news', (req) {
        final page = req.queryParameters['page'];
        return {
          'success': true,
          'data': _page([_article(page == 0 ? 1 : 2, '기사 $page')], totalPages: 2),
        };
      });
      notifier.setQuery('기사');
      await settle();

      await notifier.loadMore();
      await notifier.loadMore(); // 마지막 페이지라 더 요청 안 함

      final s = container.read(searchProvider);
      expect(s.articles.map((a) => a.title), ['기사 0', '기사 1']);
      expect(api.calls('GET', '/api/news'), hasLength(2));
    });

    test('실패하면 error, 다시 시도로 복구', () async {
      api.on('GET', '/api/news', (_) => const FakeError(500));
      notifier.setQuery('금리');
      await settle();
      expect(container.read(searchProvider).status, SearchStatus.error);

      api.onJson('GET', '/api/news', _page([_article(1, '금리 동결')]));
      await notifier.retry();
      expect(container.read(searchProvider).status, SearchStatus.loaded);
    });
  });

  group('화면', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<void> pumpApp(WidgetTester tester) async {
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen(), routes: [
          GoRoute(path: 'search', builder: (_, _) => const SearchScreen()),
        ]),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [dioProvider.overrideWithValue(api.dio())],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('홈엔 종 아이콘이 없고, 돋보기를 누르면 검색 화면', (tester) async {
      api.onJson('GET', '/api/news', _page([_article(1, '홈 기사')]));
      await pumpApp(tester);

      final bell = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter.runtimeType.toString().contains('Bell'));
      expect(bell, findsNothing);

      await tester.tap(find.byKey(const Key('home-search')));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('기사 제목으로 검색해보세요'), findsOneWidget);
    });

    testWidgets('입력하면 0.3초 뒤 결과가 나오고, 결과 없으면 안내 문구', (tester) async {
      api.onJson('GET', '/api/news', _page([_article(1, '홈 기사')]));
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('home-search')));
      await tester.pumpAndSettle();

      api.on('GET', '/api/news', (req) {
        final kw = req.queryParameters['keyword'];
        return {
          'success': true,
          'data': _page(kw == '금리' ? [_article(7, '금리 인하 발표', category: '경제')] : []),
        };
      });

      await tester.enterText(find.byKey(const Key('search-field')), '금리');
      await tester.pump(const Duration(milliseconds: 100));
      expect(api.calls('GET', '/api/news').where((r) => r.queryParameters['keyword'] != null),
          isEmpty);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('금리 인하 발표'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), '없는말');
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text("'없는말'에 맞는 기사가 없어요"), findsOneWidget);

      await tester.tap(find.byKey(const Key('search-clear')));
      await tester.pumpAndSettle();
      expect(find.text('기사 제목으로 검색해보세요'), findsOneWidget);
    });

    testWidgets('실패하면 다시 시도 버튼', (tester) async {
      api.onJson('GET', '/api/news', _page([]));
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('home-search')));
      await tester.pumpAndSettle();

      api.on('GET', '/api/news', (_) => const FakeError(500));
      await tester.enterText(find.byKey(const Key('search-field')), '금리');
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text('검색하지 못했어요'), findsOneWidget);

      api.onJson('GET', '/api/news', _page([_article(3, '금리 동결')]));
      await tester.tap(find.byKey(const Key('search-retry')));
      await tester.pumpAndSettle();
      expect(find.text('금리 동결'), findsOneWidget);
    });
  });
}
