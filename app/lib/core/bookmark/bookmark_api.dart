import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dio_client.dart';

/// 보관함 목록이 바뀌었음을 알리는 신호. 보관함 탭이 이 값을 보고 다시 불러온다.
final bookmarksRevisionProvider = StateProvider<int>((ref) => 0);

class BookmarkApi {
  final Dio _dio;
  final void Function() _onChanged;

  BookmarkApi(this._dio, this._onChanged);

  /// 저장 ↔ 저장 취소. 바뀐 뒤의 저장 여부를 돌려준다. 실패하면 예외.
  /// 화면 상태가 서버보다 늦은 경우(이미 저장됨 409 / 이미 없음 404)는 원하던 결과와 같으므로 성공으로 본다.
  Future<bool> toggle(int resultId, {required bool currentlyBookmarked}) async {
    try {
      if (currentlyBookmarked) {
        await _dio.delete('/api/bookmarks/$resultId');
      } else {
        await _dio.post('/api/bookmarks/$resultId');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final alreadyDone = currentlyBookmarked ? status == 404 : status == 409;
      if (!alreadyDone) rethrow;
    }
    _onChanged();
    return !currentlyBookmarked;
  }
}

final bookmarkApiProvider = Provider<BookmarkApi>((ref) {
  return BookmarkApi(
    ref.watch(dioProvider),
    () => ref.read(bookmarksRevisionProvider.notifier).state++,
  );
});
