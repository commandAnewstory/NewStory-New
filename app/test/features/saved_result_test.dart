import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/bookmark/bookmark_api.dart';
import 'package:newstory/core/launch/url_opener.dart';
import 'package:newstory/core/share/share_text.dart';
import 'package:newstory/features/bookmarks/bookmarks_screen.dart';
import 'package:newstory/features/bookmarks/saved_result_provider.dart';
import 'package:newstory/features/bookmarks/saved_result_screen.dart';

import '../support/fake_api.dart';

const _url = 'https://news.example.com/7';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late List<String> opened;
  late List<String> shared;

  setUp(() {
    opened = [];
    shared = [];
    api = FakeApi()
      ..onJson('GET', '/api/convert/11', {
        'id': 11,
        'style': 'novel',
        'convertedText': '그날 기준금리가 올랐다',
        'glossary': [
          {'term': '기준금리', 'definition': '한국은행이 정하는 기본 금리'}
        ],
        'bookmarked': true,
      })
      ..onJson('DELETE', '/api/bookmarks/11', null)
      ..onJson('POST', '/api/bookmarks/11', null);
  });

  List<Override> overrides() => [
        dioProvider.overrideWithValue(api.dio()),
        urlOpenerProvider.overrideWithValue((url) async {
          opened.add(url);
          return true;
        }),
        shareLauncherProvider.overrideWithValue((text, {subject}) async => shared.add(text)),
      ];

  Widget screen({String style = 'novel'}) => ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: SavedResultScreen(
            resultId: 11,
            args: SavedResultArgs(title: '테스트 기사', style: style, articleUrl: _url),
          ),
        ),
      );

  testWidgets('저장된 결과를 다시 열면 변환문과 용어풀이가 그대로 보인다', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('테스트 기사'), findsOneWidget);
    expect(find.text('소설체'), findsOneWidget);
    expect(find.textContaining('기준금리가 올랐다', findRichText: true), findsOneWidget);
    expect(find.text('용어 전체 보기'), findsOneWidget);
    expect(find.text('저장됨'), findsOneWidget);
  });

  testWidgets('카드요약이면 bullet 뷰로 보인다', (tester) async {
    api.onJson('GET', '/api/convert/11', {
      'id': 11,
      'convertedText': '- 첫째 핵심\n- 둘째 핵심',
      'glossary': [],
      'bookmarked': false,
    });
    await tester.pumpWidget(screen(style: 'card'));
    await tester.pumpAndSettle();

    expect(find.textContaining('첫째 핵심', findRichText: true), findsOneWidget);
    expect(find.text('카드요약'), findsOneWidget);
  });

  testWidgets('불러오기 실패 → 다시 시도로 복구', (tester) async {
    api.on('GET', '/api/convert/11', (_) => const FakeError(500));
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);

    api.onJson('GET', '/api/convert/11', {
      'id': 11,
      'convertedText': '복구된 결과',
      'glossary': [],
      'bookmarked': true,
    });
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.textContaining('복구된 결과', findRichText: true), findsOneWidget);
  });

  testWidgets('저장 취소하면 보관함 목록 갱신 신호가 간다', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const MaterialApp(
          home: SavedResultScreen(
            resultId: 11,
            args: SavedResultArgs(title: '테스트 기사', style: 'novel', articleUrl: _url),
          ),
        );
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saved-bookmark-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('보관함에 저장'), findsOneWidget);
    expect(api.calls('DELETE', '/api/bookmarks/11'), hasLength(1));
    expect(container.read(bookmarksRevisionProvider), 1);
  });

  testWidgets('원문 보기는 외부 브라우저로, 공유는 변환문+링크', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saved-open-original')));
    await tester.tap(find.byKey(const Key('saved-share')));
    await tester.pumpAndSettle();

    expect(opened, [_url]);
    expect(shared.single, '테스트 기사\n\n그날 기준금리가 올랐다\n\n원문: $_url');
  });

  testWidgets('보관함·히스토리 항목을 누르면 저장된 결과 화면이 열린다', (tester) async {
    api
      ..onJson('GET', '/api/bookmarks', [
        {
          'bookmarkId': 1,
          'resultId': 11,
          'style': 'novel',
          'articleTitle': '보관함 기사',
          'bookmarkedAt': '2026-10-12T09:00:00',
          'articleUrl': _url,
        }
      ])
      ..onJson('GET', '/api/history', []);
    final router = GoRouter(initialLocation: '/bookmarks', routes: [
      GoRoute(
        path: '/bookmarks',
        builder: (_, _) => const BookmarksScreen(),
        routes: [
          GoRoute(
            path: 'result/:resultId',
            builder: (_, state) => SavedResultScreen(
              resultId: int.parse(state.pathParameters['resultId']!),
              args: state.extra! as SavedResultArgs,
            ),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('보관함 기사'));
    await tester.pumpAndSettle();

    expect(find.byType(SavedResultScreen), findsOneWidget);
    expect(find.textContaining('기준금리가 올랐다', findRichText: true), findsOneWidget);
  });
}
