import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/bookmark/bookmark_api.dart';
import '../article/article_detail_provider.dart';

/// 목록에서 넘겨받는 표시용 정보. 변환 결과 단건 API엔 기사 제목·URL이 없어서 목록 응답 값을 그대로 넘긴다.
class SavedResultArgs {
  final String title;
  final String style;
  final String? articleUrl;

  const SavedResultArgs({required this.title, required this.style, this.articleUrl});
}

class SavedResultState {
  final ConvertResult? result;
  final bool isLoading;
  final String? error;
  final bool isTogglingBookmark;

  const SavedResultState({
    this.result,
    this.isLoading = true,
    this.error,
    this.isTogglingBookmark = false,
  });

  SavedResultState copyWith({
    ConvertResult? result,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isTogglingBookmark,
  }) =>
      SavedResultState(
        result: result ?? this.result,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isTogglingBookmark: isTogglingBookmark ?? this.isTogglingBookmark,
      );
}

class SavedResultNotifier extends StateNotifier<SavedResultState> {
  final Dio _dio;
  final BookmarkApi _bookmarks;
  final int resultId;

  SavedResultNotifier(this._dio, this._bookmarks, this.resultId)
      : super(const SavedResultState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get('/api/convert/$resultId');
      final data = res.data['data'] as Map<String, dynamic>;
      if (!mounted) return;
      state = state.copyWith(result: ConvertResult.fromJson(data), isLoading: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
          isLoading: false, error: '저장된 결과를 불러오지 못했어요.\n네트워크 연결을 확인하고 다시 시도해 주세요.');
    }
  }

  /// 보관함 저장 ↔ 취소. 성공하면 true, 실패하면 상태 그대로 두고 false.
  Future<bool> toggleBookmark() async {
    final current = state.result;
    if (current?.resultId == null || state.isTogglingBookmark) return false;
    state = state.copyWith(isTogglingBookmark: true);
    try {
      final bookmarked = await _bookmarks.toggle(current!.resultId!,
          currentlyBookmarked: current.bookmarked);
      state = state.copyWith(
          result: current.copyWith(bookmarked: bookmarked), isTogglingBookmark: false);
      return true;
    } catch (_) {
      state = state.copyWith(isTogglingBookmark: false);
      return false;
    }
  }
}

final savedResultProvider = StateNotifierProvider.autoDispose
    .family<SavedResultNotifier, SavedResultState, int>(
  (ref, resultId) => SavedResultNotifier(
      ref.watch(dioProvider), ref.watch(bookmarkApiProvider), resultId),
);
