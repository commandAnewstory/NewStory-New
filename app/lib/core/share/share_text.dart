import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

const _excerptLimit = 200;

/// 공유 문구 (2026-10-12 결정: 변환문 + 원문 링크).
/// - 원문 탭: 제목 + 원문 링크
/// - 카드요약: 제목 + bullet 전체(5개 이하라 짧음) + 원문 링크
/// - 동화체/소설체: 제목 + 변환문 앞부분 200자 + 원문 링크
String buildShareText({
  required String title,
  required String url,
  String? style,
  String? convertedText,
}) {
  final parts = <String>[title];
  final text = convertedText?.trim();
  if (style != null && style != 'original' && text != null && text.isNotEmpty) {
    if (style == 'card' || text.length <= _excerptLimit) {
      parts.add(text);
    } else {
      parts.add('${text.substring(0, _excerptLimit).trimRight()}…');
    }
  }
  parts.add('원문: $url');
  return parts.join('\n\n');
}

typedef ShareLauncher = Future<void> Function(String text, {String? subject});

/// 테스트에서 실제 공유 시트 대신 가짜로 바꿔 끼우기 위한 provider.
final shareLauncherProvider = Provider<ShareLauncher>((ref) {
  return (text, {subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  };
});
