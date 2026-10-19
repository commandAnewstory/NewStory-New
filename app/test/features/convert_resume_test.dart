import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/article/article_detail_screen.dart';

import '../support/fake_api.dart';

Map<String, dynamic> _result(int id, String text) => {
      'success': true,
      'data': {'id': id, 'convertedText': text, 'glossary': [], 'bookmarked': false},
    };

const _article = {
  'success': true,
  'data': {
    'id': 7,
    'title': '테스트 기사',
    'url': 'https://news.example.com/7',
    'category': '정치',
    'publishedAt': '2026-10-17T09:00:00',
  },
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late Completer<Object?> slowConvert;
  late Completer<Object?> slowArticle;

  setUp(() {
    api = FakeApi()
      ..on('GET', '/api/news/7', (_) => slowArticle.future)
      ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'LOW'})
      ..onJson('GET', '/api/convert/original', {'title': '테스트 기사', 'content': '원문 본문'})
      ..onJson('POST', '/api/news/7/view', null)
      ..on('POST', '/api/convert', (req) {
        final style = (req.data as Map)['style'];
        if (style == 'card') return slowConvert.future;
        if (style == 'novel') return _result(12, '그날 밤 소설체 이야기');
        return const FakeError(500);
      });
  });

  /// 홈 → 기사 상세 (위젯 진입은 ?style=card)
  Widget app({String initial = '/home'}) {
    final router = GoRouter(initialLocation: initial, routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open-article'),
              onPressed: () => context.push('/home/article/7'),
              child: const Text('기사 열기'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'article/:id',
            builder: (_, s) => ArticleDetailScreen(
              articleId: int.parse(s.pathParameters['id']!),
              initialStyle: s.uri.queryParameters['style'],
            ),
          ),
        ],
      ),
    ]);
    return ProviderScope(
      overrides: [dioProvider.overrideWithValue(api.dio())],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  List<Map> convertCalls() =>
      api.calls('POST', '/api/convert').map((r) => r.data as Map).toList();

  /// 로딩 스피너가 계속 돌아서 pumpAndSettle을 못 쓰는 구간
  Future<void> settleWhileSpinning(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder converting(String label) => find.text('$label 만드는 중이에요');

  Future<void> back(WidgetTester tester) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
  }

  Future<void> openFromHome(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open-article')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('위젯 진입: 난이도 안 묻고 기본 난이도로 1번만 요청 → 결과', (tester) async {
    slowArticle = Completer<Object?>();
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app(initial: '/home/article/7?style=card'));
    slowArticle.complete(_article);
    await settleWhileSpinning(tester);

    expect(converting('카드요약'), findsOneWidget);
    expect(find.text('난이도 선택'), findsNothing);
    expect(convertCalls(), hasLength(1));
    expect(convertCalls().single['level'], 'LOW');

    slowConvert.complete(_result(13, '카드 한 장 요약'));
    await tester.pumpAndSettle();
    expect(converting('카드요약'), findsNothing);
    expect(find.textContaining('카드 한 장 요약', findRichText: true), findsWidgets);
  });

  testWidgets('기사 응답 전(빈 화면 구간)에도 위젯 진입이면 만드는 중 표시', (tester) async {
    slowArticle = Completer<Object?>();
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app(initial: '/home/article/7?style=card'));
    await tester.pump();
    await tester.pump();

    slowArticle.complete(_article);
    await settleWhileSpinning(tester);
    expect(converting('카드요약'), findsOneWidget);

    // 다른 스타일 눌렀다가 다시 카드요약 → 난이도 선택이 아니라 계속 만드는 중
    await tester.tap(find.text('원문'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('카드요약'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('난이도 선택'), findsNothing);
    expect(converting('카드요약'), findsOneWidget);
    expect(convertCalls(), hasLength(1));

    slowConvert.complete(_result(13, '카드 한 장 요약'));
    await tester.pumpAndSettle();
  });

  testWidgets('생성 중에 뒤로 갔다가 다시 들어오면 만드는 중 → 끝나면 결과, 요청은 1번', (tester) async {
    slowArticle = Completer<Object?>()..complete(_article);
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('카드요약'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pump();
    expect(converting('카드요약'), findsOneWidget);

    await back(tester);
    expect(find.byType(ArticleDetailScreen), findsNothing);

    await openFromHome(tester);
    expect(converting('카드요약'), findsOneWidget, reason: '원문 탭이 아니라 보던 탭으로 다시 열림');

    slowConvert.complete(_result(13, '카드 한 장 요약'));
    await tester.pumpAndSettle();
    expect(converting('카드요약'), findsNothing);
    expect(find.text('변환 시작'), findsNothing);
    expect(convertCalls(), hasLength(1));
  });

  testWidgets('뒤로 간 사이에 생성이 끝났으면 다시 들어올 때 결과가 바로 보인다', (tester) async {
    slowArticle = Completer<Object?>()..complete(_article);
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('소설체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pump();
    await back(tester);

    await openFromHome(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('그날 밤 소설체 이야기', findRichText: true), findsOneWidget);
    expect(convertCalls(), hasLength(1));
  });

  testWidgets('원문 탭을 보다 나갔으면 다시 들어와도 원문', (tester) async {
    slowArticle = Completer<Object?>()..complete(_article);
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('소설체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('원문'));
    await tester.pumpAndSettle();
    await back(tester);

    await openFromHome(tester);
    await tester.pumpAndSettle();
    expect(find.text('원문 본문'), findsOneWidget);
  });

  testWidgets('실패한 스타일을 다시 누르면 난이도 선택 대신 실패 안내 + 다시 시도', (tester) async {
    slowArticle = Completer<Object?>()..complete(_article);
    slowConvert = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await openFromHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('동화체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작')); // 500
    await tester.pumpAndSettle();
    await tester.tap(find.text('원문'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('동화체'));
    await tester.pumpAndSettle();

    expect(find.text('난이도 선택'), findsNothing);
    expect(find.byKey(const Key('error-retry')), findsOneWidget);
  });
}
