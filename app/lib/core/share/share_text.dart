import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// 공유 문구 (2026-10-12 결정: 변환문 + 원문 링크).
/// - 원문 탭: 제목 + 원문 링크
/// - 변환 탭(동화체/소설체/카드요약): 제목 + 변환문 전체 + 원문 링크
///   (2026-10-17 사용자 요청: 200자에서 잘리던 것 → 전체)
String buildShareText({
  required String title,
  required String url,
  String? style,
  String? convertedText,
}) {
  final parts = <String>[title];
  final text = convertedText?.trim();
  if (style != null && style != 'original' && text != null && text.isNotEmpty) {
    parts.add(text);
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
