import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/launch/url_opener.dart';
import 'package:newstory/features/article/article_detail_provider.dart';
import 'package:newstory/features/article/article_detail_screen.dart';

import '../support/fake_api.dart';

const _serverMsg = '기사 본문을 가져오지 못했어요. 원문 사이트에서 확인해 주세요.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeApi api;
  late List<String> opened;

  setUp(() {
    opened = [];
    api = FakeApi()
      ..onJson('GET', '/api/news/7', {
        'id': 7,
        'title': '조선일보 기사',
        'url': 'https://www.chosun.com/x/',
        'category': '사회',
        'publishedAt': '2026-09-27T09:00:00',
      })
      ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'MEDIUM'})
      ..onJson('POST', '/api/news/7/view', null);
  });

  Widget app() => ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(api.dio()),
          urlOpenerProvider.overrideWithValue((url) async {
            opened.add(url);
            return true;
          }),
        ],
        child: const MaterialApp(home: ArticleDetailScreen(articleId: 7)),
      );

  testWidgets('서버가 본문을 못 가져오면(502) 흰 화면 대신 안내 + 원문 사이트 버튼', (tester) async {
    api.on('GET', '/api/convert/original', (_) => const FakeError(502, _serverMsg));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text(_serverMsg), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-original-site')));
    await tester.pumpAndSettle();
    expect(opened, ['https://www.chosun.com/x/']);
  });

  testWidgets('예전 서버처럼 빈 본문이 200으로 와도 흰 화면이 아니라 안내', (tester) async {
    api.onJson('GET', '/api/convert/original', {'title': '조선일보 기사', 'content': '  '});

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text(contentUnavailableMessage), findsOneWidget);
    expect(find.byKey(const Key('open-original-site')), findsOneWidget);
  });

  testWidgets('다른 실패(네트워크 등)는 기존 문구 + 다시 시도로 복구', (tester) async {
    api.on('GET', '/api/convert/original', (_) => const FakeError(500));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('네트워크 연결을 확인'), findsOneWidget);

    api.onJson('GET', '/api/convert/original', {'title': 't', 'content': '이제는 본문이 있음'});
    await tester.tap(find.byKey(const Key('error-retry')));
    await tester.pumpAndSettle();
    expect(find.text('이제는 본문이 있음'), findsOneWidget);
  });

  testWidgets('변환도 502면 서버 안내 문구 + 원문 사이트 버튼', (tester) async {
    api
      ..onJson('GET', '/api/convert/original', {'title': 't', 'content': '본문'})
      ..on('POST', '/api/convert', (_) => const FakeError(502, _serverMsg));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('동화체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변환 시작'));
    await tester.pumpAndSettle();

    expect(find.text(_serverMsg), findsOneWidget);
    expect(find.byKey(const Key('open-original-site')), findsOneWidget);
  });

  testWidgets('하단 원문 보기 버튼은 크롤링한 기사 원본 링크를 연다', (tester) async {
    api.onJson('GET', '/api/convert/original', {'title': 't', 'content': '원문 본문'});
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-original')));
    await tester.pumpAndSettle();
    expect(opened, ['https://www.chosun.com/x/']);
  });

  testWidgets('링크를 못 열면 스낵바로 알려준다', (tester) async {
    api.onJson('GET', '/api/convert/original', {'title': 't', 'content': '원문 본문'});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(api.dio()),
        urlOpenerProvider.overrideWithValue((_) async => false),
      ],
      child: const MaterialApp(home: ArticleDetailScreen(articleId: 7)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-original')));
    await tester.pump();
    expect(find.text('원문 링크를 열 수 없어요.'), findsOneWidget);
  });
}
