import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/bookmark/bookmark_api.dart';

class BookmarkItem {
  final int bookmarkId;
  final int resultId;
  final String style;
  final String articleTitle;
  final String bookmarkedAt;
  final String? articleUrl;

  const BookmarkItem({
    required this.bookmarkId,
    required this.resultId,
    required this.style,
    required this.articleTitle,
    required this.bookmarkedAt,
    this.articleUrl,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) => BookmarkItem(
        bookmarkId: json['bookmarkId'] as int,
        resultId: json['resultId'] as int,
        style: json['style'] as String,
        articleTitle: json['articleTitle'] as String,
        bookmarkedAt: json['bookmarkedAt'] as String,
        articleUrl: json['articleUrl'] as String?,
      );
}

class HistoryItem {
  final int resultId;
  final String style;
  final String articleTitle;
  final String createdAt;
  final String? articleUrl;

  const HistoryItem({
    required this.resultId,
    required this.style,
    required this.articleTitle,
    required this.createdAt,
    this.articleUrl,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        resultId: json['resultId'] as int,
        style: json['style'] as String,
        articleTitle: json['articleTitle'] as String,
        createdAt: json['createdAt'] as String,
        articleUrl: json['articleUrl'] as String?,
      );
}

class BookmarksState {
  final List<BookmarkItem> bookmarks;
  final List<HistoryItem> history;
  final bool isLoadingBookmarks;
  final bool isLoadingHistory;

  const BookmarksState({
    this.bookmarks = const [],
    this.history = const [],
    this.isLoadingBookmarks = false,
    this.isLoadingHistory = false,
  });

  BookmarksState copyWith({
    List<BookmarkItem>? bookmarks,
    List<HistoryItem>? history,
    bool? isLoadingBookmarks,
    bool? isLoadingHistory,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      history: history ?? this.history,
      isLoadingBookmarks: isLoadingBookmarks ?? this.isLoadingBookmarks,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

class BookmarksNotifier extends StateNotifier<BookmarksState> {
  final Dio _dio;

  BookmarksNotifier(this._dio) : super(const BookmarksState()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    await Future.wait([fetchBookmarks(), fetchHistory()]);
  }

  Future<void> fetchBookmarks() async {
    state = state.copyWith(isLoadingBookmarks: true);
    try {
      final res = await _dio.get('/api/bookmarks');
      final list = res.data['data'] as List<dynamic>;
      state = state.copyWith(
        bookmarks: list.map((e) => BookmarkItem.fromJson(e as Map<String, dynamic>)).toList(),
        isLoadingBookmarks: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingBookmarks: false);
    }
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final res = await _dio.get('/api/history');
      final list = res.data['data'] as List<dynamic>;
      state = state.copyWith(
        history: list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList(),
        isLoadingHistory: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  Future<void> removeBookmark(int resultId) async {
    state = state.copyWith(
      bookmarks: state.bookmarks.where((b) => b.resultId != resultId).toList(),
    );
    try {
      await _dio.delete('/api/bookmarks/$resultId');
    } catch (_) {
      await fetchBookmarks();
    }
  }

  Future<void> removeHistory(int resultId) async {
    state = state.copyWith(
      history: state.history.where((h) => h.resultId != resultId).toList(),
    );
    try {
      await _dio.delete('/api/history/$resultId');
    } catch (_) {
      await fetchHistory();
    }
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, BookmarksState>(
  (ref) {
    // 다른 화면에서 저장/취소하면 revision이 바뀌고, 그때 목록을 새로 불러온다
    ref.watch(bookmarksRevisionProvider);
    return BookmarksNotifier(ref.watch(dioProvider));
  },
);
