import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/article/article_detail_screen.dart';

import '../support/fake_api.dart';

Map<String, dynamic> _result(int id, String text) => {
      'success': true,
      'data': {'id': id, 'convertedText': text, 'glossary': [], 'bookmarked': false},
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late Completer<Object?> slowFairy;

  setUp(() {
    api = FakeApi()
      ..onJson('GET', '/api/news/7', {
        'id': 7,
        'title': '테스트 기사',
        'url': 'https://news.example.com/7',
        'category': '정치',
        'publishedAt': '2026-10-17T09:00:00',
      })
      ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'MEDIUM'})
      ..onJson('GET', '/api/convert/original', {'title': '테스트 기사', 'content': '원문 본문'})
      ..onJson('POST', '/api/news/7/view', null)
      ..on('POST', '/api/convert', (req) {
        final style = (req.data as Map)['style'];
        if (style == 'fairy_tale') return slowFairy.future;
        if (style == 'novel') return _result(12, '그날 밤 소설체 이야기');
        return const FakeError(500);
      });
  });

  Widget app() => ProviderScope(
        overrides: [dioProvider.overrideWithValue(api.dio())],
        child: const MaterialApp(home: ArticleDetailScreen(articleId: 7)),
      );

  Future<void> startConvert(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pump();
  }

  /// 늦게 오는 동화체 응답을 지금 도착시킨다
  Future<void> finishFairy(WidgetTester tester) async {
    slowFairy.complete(_result(11, '옛날 옛적에 동화체 이야기'));
    await tester.pumpAndSettle();
  }

  List<String> convertCalls(String style) => api
      .calls('POST', '/api/convert')
      .map((r) => (r.data as Map)['style'] as String)
      .where((s) => s == style)
      .toList();

  testWidgets('동화체 생성 중에 소설체로 넘어가도 둘 다 끝까지 생성된다', (tester) async {
    // Completer는 테스트 본문(가짜 시간 zone)에서 만들어야 complete가 pump로 전달된다
    slowFairy = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await startConvert(tester, '동화체');
    expect(find.byKey(const Key('busy-fairy_tale')), findsOneWidget);

    // 동화체가 아직 생성 중인데 소설체로 이동해서 생성
    await startConvert(tester, '소설체');
    await tester.pumpAndSettle();
    expect(find.textContaining('그날 밤 소설체 이야기', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('busy-fairy_tale')), findsOneWidget, reason: '동화체는 계속 생성 중');

    // 동화체 응답 도착 — 소설체 화면은 그대로
    await finishFairy(tester);
    expect(find.textContaining('그날 밤 소설체 이야기', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('busy-fairy_tale')), findsNothing);

    // 동화체 탭으로 가면 난이도 다시 안 묻고 결과가 바로 보임, 추가 요청 없음
    await tester.tap(find.text('동화체'));
    await tester.pumpAndSettle();
    expect(find.text('변환 시작'), findsNothing);
    expect(find.textContaining('옛날 옛적에 동화체 이야기', findRichText: true), findsOneWidget);
    expect(convertCalls('fairy_tale'), hasLength(1));
  });

  testWidgets('생성 중인 탭을 다시 누르면 난이도 안 묻고 로딩만 보이고 중복 요청 없음', (tester) async {
    // Completer는 테스트 본문(가짜 시간 zone)에서 만들어야 complete가 pump로 전달된다
    slowFairy = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await startConvert(tester, '동화체');
    await tester.tap(find.text('원문'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('동화체'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('변환 시작'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(convertCalls('fairy_tale'), hasLength(1));

    await finishFairy(tester);
    expect(find.textContaining('옛날 옛적에 동화체 이야기', findRichText: true), findsOneWidget);
  });

  testWidgets('한 스타일이 실패해도 다른 스타일 결과는 그대로', (tester) async {
    // Completer는 테스트 본문(가짜 시간 zone)에서 만들어야 complete가 pump로 전달된다
    slowFairy = Completer<Object?>();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await startConvert(tester, '소설체');
    await tester.pumpAndSettle();
    await startConvert(tester, '카드요약'); // 500
    await tester.pumpAndSettle();
    expect(find.text('변환에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);

    await tester.tap(find.text('소설체'));
    await tester.pumpAndSettle();
    expect(find.textContaining('그날 밤 소설체 이야기', findRichText: true), findsOneWidget);
    expect(find.text('변환에 실패했습니다. 다시 시도해 주세요.'), findsNothing);
  });
}
