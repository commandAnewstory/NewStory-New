import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/share/share_text.dart';
import 'package:newstory/features/article/article_detail_provider.dart';
import 'package:newstory/features/article/article_detail_screen.dart';

import '../support/fake_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late List<String> shared;

  setUp(() {
    shared = [];
    api = FakeApi()
      ..onJson('GET', '/api/news/7', {
        'id': 7,
        'title': '테스트 기사',
        'url': 'https://news.example.com/7',
        'category': '정치',
        'publishedAt': '2026-10-12T09:00:00',
      })
      ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'MEDIUM'})
      ..onJson('GET', '/api/convert/original', {'title': '테스트 기사', 'content': '원문 본문'})
      ..onJson('POST', '/api/news/7/view', null)
      ..onJson('POST', '/api/convert', {
        'id': 11,
        'convertedText': '옛날 옛적에 금리가 올랐어요',
        'glossary': [],
        'bookmarked': false,
      })
      ..onJson('POST', '/api/bookmarks/11', null)
      ..onJson('DELETE', '/api/bookmarks/11', null);
  });

  Widget app() => ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(api.dio()),
          shareLauncherProvider.overrideWithValue((text, {subject}) async => shared.add(text)),
        ],
        child: const MaterialApp(home: ArticleDetailScreen(articleId: 7)),
      );

  Future<void> convertToFairyTale(WidgetTester tester) async {
    await tester.tap(find.text('동화체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pumpAndSettle();
  }

  testWidgets('원문 탭에선 저장 버튼이 아무 요청도 안 보낸다', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bookmark-toggle')));
    await tester.pumpAndSettle();

    expect(api.calls('POST', '/api/bookmarks/11'), isEmpty);
  });

  testWidgets('변환 후 저장 → 저장됨, 다시 누르면 저장 취소', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await convertToFairyTale(tester);

    expect(find.text('보관함에 저장'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bookmark-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('저장됨'), findsOneWidget);
    expect(api.calls('POST', '/api/bookmarks/11'), hasLength(1));

    await tester.tap(find.byKey(const Key('bookmark-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('보관함에 저장'), findsOneWidget);
    expect(api.calls('DELETE', '/api/bookmarks/11'), hasLength(1));
  });

  testWidgets('저장 실패하면 상태 그대로 두고 안내', (tester) async {
    api.on('POST', '/api/bookmarks/11', (_) => const FakeError(500));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await convertToFairyTale(tester);

    await tester.tap(find.byKey(const Key('bookmark-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('보관함에 저장'), findsOneWidget);
    expect(find.textContaining('저장에 실패'), findsOneWidget);
  });

  testWidgets('이미 저장된 결과면 처음부터 저장됨으로 보인다', (tester) async {
    api.onJson('POST', '/api/convert', {
      'id': 11,
      'convertedText': '옛날 옛적에',
      'glossary': [],
      'bookmarked': true,
    });
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await convertToFairyTale(tester);

    expect(find.text('저장됨'), findsOneWidget);
  });

  testWidgets('공유: 원문 탭은 제목+링크, 변환 탭은 변환문 포함', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('share-button')));
    await tester.pumpAndSettle();
    expect(shared.last, '테스트 기사\n\n원문: https://news.example.com/7');

    await convertToFairyTale(tester);
    await tester.tap(find.byKey(const Key('share-button')));
    await tester.pumpAndSettle();
    expect(shared.last,
        '테스트 기사\n\n옛날 옛적에 금리가 올랐어요\n\n원문: https://news.example.com/7');
  });

  test('저장 요청 중에 또 누르면 무시한다 (연타 방지)', () async {
    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
    container.listen(articleDetailProvider(7), (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final notifier = container.read(articleDetailProvider(7).notifier);
    await notifier.selectStyle('fairy_tale');

    final results = await Future.wait([notifier.toggleBookmark(), notifier.toggleBookmark()]);

    expect(results, [true, false]);
    expect(api.calls('POST', '/api/bookmarks/11'), hasLength(1));
    container.dispose();
  });
}
