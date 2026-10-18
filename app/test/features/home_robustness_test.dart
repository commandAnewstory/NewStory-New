import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/auth/auth_notifier.dart';
import 'package:newstory/core/router/app_router.dart';
import 'package:newstory/features/home/article.dart';
import 'package:newstory/features/home/home_screen.dart';
import 'package:newstory/main.dart';

import '../support/fake_api.dart';

/// 직접 변환으로 저장된 기사: 카테고리·발행시각이 null
const _userConverted = {
  'id': 99,
  'title': '직접 변환한 기사',
  'description': null,
  'url': 'https://news.example.com/99',
  'source': null,
  'category': null,
  'sourceType': 'rss',
  'publishedAt': null,
};

const _rss = {
  'id': 1,
  'title': 'RSS 기사',
  'url': 'https://news.example.com/1',
  'source': '테스트일보',
  'category': '정치',
  'publishedAt': '2026-10-18T09:00:00',
};

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('카테고리·발행시각이 없는 기사도 파싱된다', () {
    final a = Article.fromJson(Map<String, dynamic>.from(_userConverted));
    expect(a.title, '직접 변환한 기사');
    expect(a.category, '');
    expect(a.publishedAt, '');
  });

  testWidgets('목록에 그런 기사가 섞여 있어도 홈이 다시 시도 화면이 아니라 목록을 보여준다', (tester) async {
    final api = FakeApi()
      ..onJson('GET', '/api/news', {
        'content': [_userConverted, _rss],
        'totalPages': 1,
      });
    await tester.pumpWidget(ProviderScope(
      overrides: [dioProvider.overrideWithValue(api.dio())],
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('다시 시도'), findsNothing);
    expect(find.text('직접 변환한 기사'), findsOneWidget);
    expect(find.text('RSS 기사'), findsOneWidget);
  });

  testWidgets('모르는 경로로 들어오면 Page Not Found 대신 홈', (tester) async {
    final api = FakeApi()..onJson('GET', '/api/news', {'content': [_rss], 'totalPages': 1});
    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
    addTearDown(container.dispose);
    await container.read(authProvider.notifier).login('a', 'r');
    await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NewStoryApp()));
    await tester.pumpAndSettle();

    // Flutter 기본 딥링크가 위젯 링크 newstory://article/7 을 넘기던 모양
    container.read(routerProvider).go('/7?style=card');
    await tester.pumpAndSettle();

    expect(find.textContaining('Page Not Found'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
