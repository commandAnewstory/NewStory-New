import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/core/api/dio_client.dart';
import 'package:newstory/features/my/my_screen.dart';

import '../support/fake_api.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('MY 화면엔 프로필·위젯 카드·로그아웃만 있고 동작 없던 메뉴는 없다', (tester) async {
    final api = FakeApi()
      ..onJson('GET', '/api/users/me', {
        'id': 1,
        'email': 'me@newstory.test',
        'nickname': '예준',
        'widgetEnabled': false,
        'lastGlossaryLevel': 'MEDIUM',
      });

    await tester.pumpWidget(ProviderScope(
      overrides: [dioProvider.overrideWithValue(api.dio())],
      child: const MaterialApp(home: MyScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('예준'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    for (final removed in ['계정 정보', '알림 설정', '언어', '문의하기', '이용약관']) {
      expect(find.text(removed), findsNothing, reason: removed);
    }
  });
}
