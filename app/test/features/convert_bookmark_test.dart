import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/convert/convert_provider.dart';

import '../support/fake_api.dart';

void main() {
  test('직접 변환 결과도 보관함 저장 ↔ 취소가 된다', () async {
    final api = FakeApi()
      ..onJson('POST', '/api/convert', {
        'id': 21,
        'convertedText': '변환문',
        'glossary': [],
        'bookmarked': false,
      })
      ..onJson('POST', '/api/bookmarks/21', null)
      ..onJson('DELETE', '/api/bookmarks/21', null);
    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
    final notifier = container.read(convertProvider.notifier)
      ..setUrl('https://news.example.com/x')
      ..setStyle('novel');
    await notifier.convert();
    expect(container.read(convertProvider).result!.resultId, 21);

    expect(await notifier.toggleBookmark(), isTrue);
    expect(container.read(convertProvider).result!.bookmarked, isTrue);

    expect(await notifier.toggleBookmark(), isTrue);
    expect(container.read(convertProvider).result!.bookmarked, isFalse);
    expect(api.calls('POST', '/api/bookmarks/21'), hasLength(1));
    expect(api.calls('DELETE', '/api/bookmarks/21'), hasLength(1));
    container.dispose();
  });
}
