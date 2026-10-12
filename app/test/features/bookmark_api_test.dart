import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/core/bookmark/bookmark_api.dart';

import '../support/fake_api.dart';

void main() {
  late FakeApi api;
  late ProviderContainer container;

  setUp(() {
    api = FakeApi();
    container = ProviderContainer(overrides: [dioProvider.overrideWithValue(api.dio())]);
  });

  BookmarkApi bookmarks() => container.read(bookmarkApiProvider);
  int revision() => container.read(bookmarksRevisionProvider);

  test('저장 안 된 상태에서 누르면 POST, 저장된 상태면 DELETE', () async {
    api
      ..onJson('POST', '/api/bookmarks/3', null)
      ..onJson('DELETE', '/api/bookmarks/3', null);

    expect(await bookmarks().toggle(3, currentlyBookmarked: false), isTrue);
    expect(await bookmarks().toggle(3, currentlyBookmarked: true), isFalse);
    expect(api.calls('POST', '/api/bookmarks/3'), hasLength(1));
    expect(api.calls('DELETE', '/api/bookmarks/3'), hasLength(1));
    expect(revision(), 2, reason: '보관함 탭이 다시 불러오도록 신호');
  });

  test('이미 저장돼 있으면(409) 저장 성공으로 본다', () async {
    api.on('POST', '/api/bookmarks/3', (_) => const FakeError(409));

    expect(await bookmarks().toggle(3, currentlyBookmarked: false), isTrue);
  });

  test('이미 없으면(404) 취소 성공으로 본다', () async {
    api.on('DELETE', '/api/bookmarks/3', (_) => const FakeError(404));

    expect(await bookmarks().toggle(3, currentlyBookmarked: true), isFalse);
  });

  test('서버 오류면 예외를 던지고 신호도 안 보낸다', () async {
    api.on('POST', '/api/bookmarks/3', (_) => const FakeError(500));

    await expectLater(bookmarks().toggle(3, currentlyBookmarked: false), throwsA(anything));
    expect(revision(), 0);
  });
}
