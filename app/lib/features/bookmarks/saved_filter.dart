import 'bookmarks_provider.dart';

/// 보관함·히스토리 목록 한 줄 (둘을 같은 모양으로 그리고 같은 필터를 쓰려고 맞춘 것)
class SavedEntry {
  final int resultId;
  final String style;
  final String title;
  final String? category;

  /// 보관함: 저장한 시각, 히스토리: 마지막으로 본 시각 (ISO 문자열)
  final String time;
  final String? articleUrl;

  const SavedEntry({
    required this.resultId,
    required this.style,
    required this.title,
    required this.category,
    required this.time,
    this.articleUrl,
  });

  factory SavedEntry.fromBookmark(BookmarkItem b) => SavedEntry(
        resultId: b.resultId,
        style: b.style,
        title: b.articleTitle,
        category: b.category,
        time: b.bookmarkedAt,
        articleUrl: b.articleUrl,
      );

  factory SavedEntry.fromHistory(HistoryItem h) => SavedEntry(
        resultId: h.resultId,
        style: h.style,
        title: h.articleTitle,
        category: h.category,
        time: h.viewedAt ?? h.createdAt,
        articleUrl: h.articleUrl,
      );
}

/// 변환종류 필터 값. 'all'이면 전체
const savedStyleOptions = [
  ('all', '전체'),
  ('fairy_tale', '동화체'),
  ('novel', '소설체'),
  ('card', '카드요약'),
];

class SavedFilter {
  final String query;

  /// '전체' 또는 카테고리 이름
  final String category;

  /// 'all' 또는 변환종류
  final String style;

  const SavedFilter({this.query = '', this.category = '전체', this.style = 'all'});

  bool get isActive => query.trim().isNotEmpty || category != '전체' || style != 'all';

  SavedFilter copyWith({String? query, String? category, String? style}) => SavedFilter(
        query: query ?? this.query,
        category: category ?? this.category,
        style: style ?? this.style,
      );

  /// 제목 부분 일치(대소문자·앞뒤 공백 무시) + 카테고리 + 변환종류, 셋 다 AND.
  /// 카테고리 없는 항목(직접 변환한 기사)은 카테고리가 '전체'일 때만 보인다.
  bool matches(SavedEntry e) {
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && !e.title.toLowerCase().contains(q)) return false;
    if (category != '전체' && e.category != category) return false;
    if (style != 'all' && e.style != style) return false;
    return true;
  }

  List<SavedEntry> apply(List<SavedEntry> entries) => entries.where(matches).toList();
}
