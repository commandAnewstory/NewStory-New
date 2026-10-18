import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_client.dart';
import '../auth/auth_notifier.dart';
import 'home_widget_platform.dart';

/// 앱 시작 시 위젯 갱신. 로그인돼 있으면 서버의 위젯 토글·관심 카테고리를 먼저 맞추고(다른 기기에서 바꿨거나
/// 재설치한 경우), 실패하거나 로그아웃 상태면 마지막으로 반영된 값으로 갱신한다.
final homeWidgetStartupSyncProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final service = ref.read(homeWidgetServiceProvider);
    if (ref.read(authProvider).isLoggedIn) {
      try {
        final res = await ref.read(dioProvider).get('/api/users/me');
        final data = res.data['data'] as Map<String, dynamic>;
        final enabled = data['widgetEnabled'] as bool?;
        if (enabled != null) {
          final categories =
              ((data['interestCategories'] as List?) ?? const []).cast<String>();
          await service.applyProfile(enabled: enabled, categories: categories);
          return;
        }
      } catch (_) {}
    }
    await service.refresh();
  };
});
