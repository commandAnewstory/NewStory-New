import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/features/home/widgets/category_chip_bar.dart';

void main() {
  test('수집 소스가 없는 국제 카테고리는 칩에서 빠져 있다', () {
    expect(categories, isNot(contains('국제')));
    expect(categories.first, '전체');
  });
}
