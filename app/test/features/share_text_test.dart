import 'package:flutter_test/flutter_test.dart';
import 'package:newstory/core/share/share_text.dart';

void main() {
  const url = 'https://news.example.com/1';

  test('원문 탭은 제목 + 원문 링크', () {
    expect(buildShareText(title: '기사 제목', url: url, style: 'original'),
        '기사 제목\n\n원문: $url');
  });

  test('동화체·소설체는 변환문 앞 200자 + 말줄임표', () {
    final long = '가' * 250;
    final text = buildShareText(
        title: '기사 제목', url: url, style: 'novel', convertedText: long);

    expect(text, '기사 제목\n\n${'가' * 200}…\n\n원문: $url');
  });

  test('짧은 변환문은 자르지 않는다', () {
    expect(
        buildShareText(
            title: '기사 제목', url: url, style: 'fairy_tale', convertedText: '옛날 옛적에'),
        '기사 제목\n\n옛날 옛적에\n\n원문: $url');
  });

  test('카드요약은 bullet 전체', () {
    final bullets = List.generate(5, (i) => '- 핵심 ${'내용' * 30} $i').join('\n');
    final text = buildShareText(
        title: '기사 제목', url: url, style: 'card', convertedText: bullets);

    expect(text, '기사 제목\n\n$bullets\n\n원문: $url');
  });
}
