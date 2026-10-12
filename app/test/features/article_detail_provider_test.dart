import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/article/article_detail_provider.dart';

import '../support/fake_api.dart';

void main() {
  late FakeApi api;
  late ProviderContainer container;

  setUp(() {
    api = FakeApi()
      ..onJson('GET', '/api/news/7', {
        'id': 7,
        'title': '테스트 기사',
        'url': 'https://news.example.com/7',
        'category': '정치',
        'publishedAt': '2026-10-12T09:00:00',
      })
      ..onJson('GET', '/api/users/me', {'lastGlossaryLevel': 'HIGH'})
      ..onJson('GET', '/api/convert/original', {'title': '테스트 기사', 'content': '원문'})
      ..onJson('POST', '/api/news/7/view', null)
      ..on('POST', '/api/convert', (req) => {
            'success': true,
            'data': {
              'id': 1,
              'convertedText': '변환문',
              'glossary': [],
              'level': (req.data as Map)['level'],
            }
          });
    container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
  });

  tearDown(() => container.dispose());

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('기사 상세에 들어가면 조회수를 한 번 기록한다', () async {
    container.listen(articleDetailProvider(7), (_, _) {});
    await settle();

    expect(api.calls('POST', '/api/news/7/view'), hasLength(1));
  });

  test('레벨 기본값은 사용자의 마지막 선택 레벨', () async {
    container.listen(articleDetailProvider(7), (_, _) {});
    await settle();

    expect(container.read(articleDetailProvider(7)).defaultLevel, 'HIGH');
  });

  test('변환하면 그 레벨이 다음 기본값이 된다', () async {
    container.listen(articleDetailProvider(7), (_, _) {});
    await settle();

    await container.read(articleDetailProvider(7).notifier).selectStyle('novel', level: 'LOW');

    expect(container.read(articleDetailProvider(7)).defaultLevel, 'LOW');
    expect(api.calls('POST', '/api/convert').single.data, containsPair('level', 'LOW'));
  });

  test('조회수 기록이 실패해도 기사는 정상 로드된다', () async {
    api.on('POST', '/api/news/7/view', (_) => const FakeError(500));
    container.listen(articleDetailProvider(7), (_, _) {});
    await settle();

    final state = container.read(articleDetailProvider(7));
    expect(state.title, '테스트 기사');
    expect(state.isLoadingArticle, isFalse);
  });
}
