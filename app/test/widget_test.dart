import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/main.dart';

void main() {
  testWidgets('app smoke test', (tester) async {
    await tester.pumpWidget(const NewStoryApp());
  });
}
