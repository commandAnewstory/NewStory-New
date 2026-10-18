import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newstory/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('로그인 안 된 상태로 앱을 켜면 로그인 화면이 뜬다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NewStoryApp()));
    await tester.pumpAndSettle();

    expect(find.textContaining('로그인'), findsWidgets);
  });
}
