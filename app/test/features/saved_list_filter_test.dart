import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/bookmarks/bookmarks_screen.dart';
import 'package:newstory/features/bookmarks/saved_filter.dart';

import '../support/fake_api.dart';

Map<String, dynamic> _bookmark(int id, String title, String style, String? category) => {
      'bookmarkId': id,
      'resultId': id,
      'style': style,
      'articleTitle': title,
      'bookmarkedAt': '2026-10-18T09:00:00',
      'articleUrl': 'https://news.example.com/$id',
      'level': 'MEDIUM',
      'category': category,
    };

Map<String, dynamic> _history(int id, String title, String style, String? category) => {
      'resultId': id,
      'style': style,
      'articleTitle': title,
      'createdAt': '2026-10-17T09:00:00',
      'viewedAt': '2026-10-18T10:00:00',
      'articleUrl': 'https://news.example.com/$id',
      'level': 'MEDIUM',
      'category': category,
    };

SavedEntry _e(String title, String style, String? category) => SavedEntry(
    resultId: title.hashCode, style: style, title: title, category: category, time: '');

void main() {
  group('SavedFilter', () {
    final entries = [
      _e('금리 동결 발표', 'card', '경제'),
      _e('국회 본회의 통과', 'fairy_tale', '정치'),
      _e('OpenAI 새 모델', 'novel', 'IT'),
      _e('직접 변환한 금리 기사', 'card', null),
    ];

    List<String> titles(SavedFilter f) => f.apply(entries).map((e) => e.title).toList();

    test('제목 부분 일치, 대소문자·앞뒤 공백 무시', () {
      expect(titles(const SavedFilter(query: ' 금리 ')), ['금리 동결 발표', '직접 변환한 금리 기사']);
      expect(titles(const SavedFilter(query: 'openai')), ['OpenAI 새 모델']);
    });

    test('카테고리 필터 — 카테고리 없는 항목은 전체일 때만', () {
      expect(titles(const SavedFilter(category: '경제')), ['금리 동결 발표']);
      expect(titles(const SavedFilter()), hasLength(4));
    });

    test('변환종류 필터', () {
      expect(titles(const SavedFilter(style: 'card')), ['금리 동결 발표', '직접 변환한 금리 기사']);
    });

    test('셋 다 AND', () {
      expect(titles(const SavedFilter(query: '금리', category: '경제', style: 'card')), ['금리 동결 발표']);
      expect(titles(const SavedFilter(query: '금리', category: '정치')), isEmpty);
    });
  });

  group('보관함 화면', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    late FakeApi api;

    setUp(() {
      api = FakeApi()
        ..onJson('GET', '/api/bookmarks', [
          _bookmark(1, '금리 동결 발표', 'card', '경제'),
          _bookmark(2, '국회 본회의 통과', 'fairy_tale', '정치'),
          _bookmark(3, '직접 변환한 금리 기사', 'novel', null),
        ])
        ..onJson('GET', '/api/history', [
          _history(4, '금리 인하 전망', 'novel', '경제'),
          _history(5, '야구 결승전', 'card', '스포츠'),
        ])
        ..onJson('GET', '/api/convert/1', {
          'id': 1,
          'convertedText': '- 기준금리 동결',
          'glossary': [],
          'bookmarked': true,
        });
    });

    Future<void> pump(WidgetTester tester) async {
      final router = GoRouter(initialLocation: '/bookmarks', routes: [
        GoRoute(path: '/bookmarks', builder: (_, _) => const BookmarksScreen(), routes: [
          GoRoute(
              path: 'result/:id',
              builder: (_, s) => Scaffold(body: Text('결과 화면 ${s.pathParameters['id']}'))),
        ]),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [dioProvider.overrideWithValue(api.dio())],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('홈 스타일 목록: 카테고리 배지·변환종류·제목, 카테고리 없으면 배지 생략', (tester) async {
      await pump(tester);

      expect(find.text('금리 동결 발표'), findsOneWidget);
      expect(find.text('경제'), findsWidgets); // 배지 + 필터 칩
      expect(find.text('카드요약'), findsWidgets);
      expect(find.byKey(const Key('saved-tile-3')), findsOneWidget);
    });

    testWidgets('검색·카테고리·변환종류가 같이 걸리고 보관함↔히스토리 바꿔도 유지', (tester) async {
      await pump(tester);

      await tester.enterText(find.byKey(const Key('saved-search')), '금리');
      await tester.pump();
      expect(find.text('국회 본회의 통과'), findsNothing);
      expect(find.text('금리 동결 발표'), findsOneWidget);
      expect(find.text('직접 변환한 금리 기사'), findsOneWidget);

      await tester.tap(find.text('경제').first); // 카테고리 칩
      await tester.pump();
      expect(find.text('직접 변환한 금리 기사'), findsNothing, reason: '카테고리 없는 기사는 전체에만');
      expect(find.text('금리 동결 발표'), findsOneWidget);

      await tester.tap(find.text('히스토리'));
      await tester.pumpAndSettle();
      expect(find.text('금리 인하 전망'), findsOneWidget);
      expect(find.text('야구 결승전'), findsNothing);

      await tester.tap(find.byKey(const Key('style-filter-card')));
      await tester.pump();
      expect(find.text('조건에 맞는 항목이 없어요'), findsOneWidget);

      await tester.tap(find.byKey(const Key('saved-filter-reset')));
      await tester.pump();
      expect(find.text('금리 인하 전망'), findsOneWidget);
      expect(find.text('야구 결승전'), findsOneWidget);
    });

    testWidgets('항목을 누르면 저장된 결과 화면으로', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('saved-tile-1')));
      await tester.pumpAndSettle();
      expect(find.text('결과 화면 1'), findsOneWidget);
    });

    testWidgets('길게 눌러 삭제', (tester) async {
      api.onJson('DELETE', '/api/bookmarks/2', null);
      await pump(tester);

      await tester.longPress(find.byKey(const Key('saved-tile-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      expect(find.text('국회 본회의 통과'), findsNothing);
      expect(api.calls('DELETE', '/api/bookmarks/2'), hasLength(1));
    });
  });
}
