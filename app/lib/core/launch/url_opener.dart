import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(String url);

/// 외부 브라우저로 링크 열기. 테스트에서 가짜로 바꿔 끼울 수 있게 provider로 둔다.
final urlOpenerProvider = Provider<UrlOpener>((ref) {
  return (url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  };
});
