import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/auth/auth_notifier.dart';
import 'package:newstory/core/convert/convert_jobs.dart';
import 'package:newstory/core/convert/convert_jobs_fab.dart';
import 'package:newstory/features/article/article_detail_screen.dart';

import '../support/fake_api.dart';

Map<String, dynamic> _result(int id, String text) => {
      'success': true,
      'data': {'id': id, 'convertedText': text, 'glossary': [], 'bookmarked': false},
    };

Map<String, dynamic> _article(int id, String title) => {
      'id': id,
      'title': title,
      'url': 'https://news.example.com/$id',
      'category': '정치',
      'publishedAt': '2026-10-17T09:00:00',
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ConvertJobsNotifier', () {
    test('끝난 작업만 봤을 때 빠지고, 생성 중인 건 남는다', () {
      final n = ConvertJobsNotifier()
        ..start(1, 'card', '기사1')
        ..start(2, 'novel', '기사2');
      n.seen(1, 'card');
      expect(n.state, hasLength(2), reason: '생성 중이면 안 빠짐');

      n.finish(1, 'card', success: true);
      n.finish(2, 'novel', success: false);
      expect(n.state.map((j) => j.status), [ConvertJobStatus.done, ConvertJobStatus.failed]);

      n.seen(1, 'card');
      expect(n.state.single.articleId, 2);
    });

    test('비운 뒤 늦게 끝난 요청은 다시 안 들어온다 (로그아웃 후)', () {
      final n = ConvertJobsNotifier()..start(1, 'card', '기사1');
      n.clear();
      n.finish(1, 'card', success: true);
      expect(n.state, isEmpty);
    });
  });

  group('플로팅 버튼', () {
    late FakeApi api;
    late Completer<Object?> slow7;
    late Completer<Object?> slow8;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      api = FakeApi()
        ..onJson('GET', '/api/news/7', _article(7, '금리 동결 발표'))
        ..onJson('GET', '/api/news/8', _article(8, '새 스마트폰 출시'))
        ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'MEDIUM'})
        ..onJson('GET', '/api/convert/original', {'title': 't', 'content': '원문 본문'})
        ..onJson('POST', '/api/news/7/view', null)
        ..onJson('POST', '/api/news/8/view', null)
        ..on('POST', '/api/convert', (req) {
          final url = (req.data as Map)['url'] as String;
          return url.endsWith('/7') ? slow7.future : slow8.future;
        });
    });

    tearDown(() => container.dispose());

    Future<void> pumpApp(WidgetTester tester) async {
      container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
      await container.read(authProvider.notifier).login('a', 'r');
      router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: Column(children: [
              for (final id in [7, 8])
                TextButton(
                  key: Key('open-$id'),
                  onPressed: () => context.push('/home/article/$id'),
                  child: Text('기사 $id 열기'),
                ),
            ]),
          ),
          routes: [
            GoRoute(
              path: 'article/:id',
              builder: (_, s) => ArticleDetailScreen(articleId: int.parse(s.pathParameters['id']!)),
            ),
          ],
        ),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => withConvertJobsFab(router, child),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// 버튼 로딩 링이 계속 돌면 pumpAndSettle이 안 끝나서 시간만 흘린다
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> startCard(WidgetTester tester, int id) async {
      await tester.tap(find.byKey(Key('open-$id')));
      await settle(tester);
      await tester.tap(find.text('카드요약'));
      await settle(tester);
      await tester.tap(find.text('변환 시작'));
      await tester.pump();
    }

    Future<void> back(WidgetTester tester) async {
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    final fab = find.byKey(const Key('convert-fab'));

    testWidgets('변환 중에 나가면 노란 버튼(로딩) → 끝나면 완료 표시 → 목록에서 눌러 들어가면 사라짐', (tester) async {
      slow7 = Completer<Object?>();
      slow8 = Completer<Object?>();
      await pumpApp(tester);
      expect(fab, findsNothing, reason: '변환 없으면 버튼 없음');

      await startCard(tester, 7);
      expect(fab, findsNothing, reason: '그 기사 화면에선 안 보임');

      await back(tester);
      expect(fab, findsOneWidget);
      expect(find.byKey(const Key('convert-fab-running')), findsOneWidget);

      slow7.complete(_result(21, '카드 요약 결과'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const Key('convert-fab-done')), findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('convert-jobs-sheet')), findsOneWidget);
      expect(find.text('금리 동결 발표'), findsOneWidget);
      expect(find.text('완료'), findsOneWidget);

      await tester.tap(find.byKey(const Key('convert-job-7-card')));
      await tester.pumpAndSettle();
      expect(find.byType(ArticleDetailScreen), findsOneWidget);
      expect(find.text('변환 시작'), findsNothing);
      expect(container.read(convertJobsProvider), isEmpty, reason: '결과를 봤으니 목록에서 빠짐');

      await back(tester);
      expect(fab, findsNothing);
    });

    testWidgets('여러 개면 개수 배지 + 목록에 각각 상태', (tester) async {
      slow7 = Completer<Object?>();
      slow8 = Completer<Object?>();
      await pumpApp(tester);

      await startCard(tester, 7);
      await back(tester);
      await startCard(tester, 8);
      // 기사 8 화면: 7번 작업만 보이니까 버튼 있음
      expect(fab, findsOneWidget);
      await back(tester);

      expect(find.byKey(const Key('convert-fab-count')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      slow8.complete(const FakeError(500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('금리 동결 발표'), findsOneWidget);
      expect(find.text('새 스마트폰 출시'), findsOneWidget);
      expect(find.text('만드는 중'), findsOneWidget);
      expect(find.text('실패'), findsOneWidget);

      // 실패한 기사로 들어가면 난이도 선택이 아니라 실패 안내
      await tester.tap(find.byKey(const Key('convert-job-8-card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('error-retry')), findsOneWidget);
      expect(find.text('난이도 선택'), findsNothing);

      slow7.complete(_result(21, '카드 요약 결과'));
      await tester.pumpAndSettle();
    });

    testWidgets('로그아웃하면 버튼과 목록이 사라진다', (tester) async {
      slow7 = Completer<Object?>();
      slow8 = Completer<Object?>();
      await pumpApp(tester);
      await startCard(tester, 7);
      await back(tester);
      expect(fab, findsOneWidget);

      await container.read(authProvider.notifier).logout(notifyServer: false);
      await tester.pump();
      expect(fab, findsNothing);
      expect(container.read(convertJobsProvider), isEmpty);

      slow7.complete(_result(21, '카드 요약 결과'));
      await tester.pumpAndSettle();
      expect(container.read(convertJobsProvider), isEmpty, reason: '로그아웃 뒤 끝난 요청은 안 들어옴');
    });
  });
}
