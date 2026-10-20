import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_notifier.dart';

enum ConvertJobStatus { running, done, failed }

/// 화면 밖에서도 보이는 변환 작업 하나 (기사 + 스타일)
class ConvertJob {
  final int articleId;
  final String style;
  final String title;
  final ConvertJobStatus status;

  const ConvertJob({
    required this.articleId,
    required this.style,
    required this.title,
    required this.status,
  });

  ConvertJob withStatus(ConvertJobStatus s) =>
      ConvertJob(articleId: articleId, style: style, title: title, status: s);

  bool same(int id, String st) => articleId == id && style == st;
}

/// 진행 중·완료·실패한 변환 목록. 기사 상세에서 그 결과(또는 실패 안내)를 보면 목록에서 빠진다.
class ConvertJobsNotifier extends StateNotifier<List<ConvertJob>> {
  ConvertJobsNotifier() : super(const []);

  void start(int articleId, String style, String title) {
    state = [
      ...state.where((j) => !j.same(articleId, style)),
      ConvertJob(articleId: articleId, style: style, title: title, status: ConvertJobStatus.running),
    ];
  }

  /// 목록에 있는 작업만 갱신 (로그아웃으로 비운 뒤 늦게 끝난 요청은 다시 안 넣음)
  void finish(int articleId, String style, {required bool success}) {
    final status = success ? ConvertJobStatus.done : ConvertJobStatus.failed;
    state = [for (final j in state) j.same(articleId, style) ? j.withStatus(status) : j];
  }

  /// 사용자가 그 결과를 봤음 — 끝난 작업이면 목록에서 뺀다 (생성 중이면 그대로)
  void seen(int articleId, String style) {
    if (!state.any((j) => j.same(articleId, style) && j.status != ConvertJobStatus.running)) return;
    state = state.where((j) => !j.same(articleId, style)).toList();
  }

  void clear() => state = const [];
}

final convertJobsProvider = StateNotifierProvider<ConvertJobsNotifier, List<ConvertJob>>((ref) {
  final notifier = ConvertJobsNotifier();
  // 로그아웃하면 비운다 (다른 계정으로 들어와도 안 보이게)
  ref.listen<AuthState>(authProvider, (prev, next) {
    if (!next.isLoggedIn) notifier.clear();
  });
  return notifier;
});
