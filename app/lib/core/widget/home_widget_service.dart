import 'package:dio/dio.dart';

/// 홈스크린 위젯(Android)과 주고받는 키. 네이티브 `TodayCardsWidget.kt`가 같은 이름으로 읽는다.
class WidgetKeys {
  static const enabled = 'enabled';
  static const state = 'state';
  static const cardCount = 'card_count';

  /// 관심 카테고리 (쉼표 구분, 빈 값 = 전체). 백그라운드 갱신이 로그인 없이 쓰려고 위젯 저장소에 둔다.
  static const categories = 'categories';
  static String title(int i) => 'card_${i}_title';

  /// 줄 오른쪽 배지 — 기사 카테고리
  static String badge(int i) => 'card_${i}_badge';

  /// 누르면 열 기사 id (문자열로 저장 — 네이티브에서 Int/Long 구분 없이 읽으려고)
  static String articleId(int i) => 'card_${i}_id';
}

/// 위젯에 보여줄 상태: 뉴스 있음 / 뉴스 없음 / MY에서 꺼짐
class WidgetStates {
  static const ok = 'ok';
  static const empty = 'empty';
  static const disabled = 'disabled';
}

const maxWidgetCards = 3;

/// 위젯 "관심 뉴스" 한 줄 (`GET /api/widget/popular`)
class WidgetNews {
  final int articleId;
  final String title;
  final String category;

  const WidgetNews({required this.articleId, required this.title, required this.category});

  factory WidgetNews.fromJson(Map<String, dynamic> json) => WidgetNews(
        articleId: (json['articleId'] as num).toInt(),
        title: (json['title'] as String?) ?? '',
        category: (json['category'] as String?) ?? '',
      );
}

/// 위젯과 공유하는 저장소 (실제 구현은 home_widget)
abstract class WidgetStore {
  Future<T?> read<T>(String key);
  Future<void> save<T>(String key, T? value);

  /// 저장한 값으로 위젯을 다시 그린다
  Future<void> redraw();
}

/// 주기 갱신 예약 (실제 구현은 workmanager)
abstract class WidgetScheduler {
  Future<void> start();
  Future<void> stop();
}

typedef WidgetNewsFetcher = Future<List<WidgetNews>> Function(List<String> categories);

/// `GET /api/widget/popular?categories=` — 로그인 없이 호출하는 공개 API라 인증 헤더 없는 Dio를 쓴다
WidgetNewsFetcher popularNewsFetcher(Dio dio) => (categories) async {
      final res = await dio.get('/api/widget/popular', queryParameters: {
        if (categories.isNotEmpty) 'categories': categories.join(','),
      });
      final list = (res.data['data'] as List?) ?? const [];
      return list.map((e) => WidgetNews.fromJson(e as Map<String, dynamic>)).toList();
    };

/// 위젯 데이터 갱신 로직. 플랫폼 코드와 분리해서 단위 테스트한다.
/// 위젯 쪽 실패가 앱 동작을 막으면 안 되니까 바깥으로 예외를 던지지 않는다.
class HomeWidgetService {
  final WidgetNewsFetcher fetchNews;
  final WidgetStore store;
  final WidgetScheduler scheduler;

  HomeWidgetService({
    required this.fetchNews,
    required this.store,
    required this.scheduler,
  });

  /// 서버 프로필 값(위젯 토글 + 관심 카테고리)을 위젯에 반영.
  /// 켜져 있으면 바로 갱신하고 주기 갱신 시작, 꺼져 있으면 안내 문구 + 주기 갱신 중단.
  Future<void> applyProfile({required bool enabled, required List<String> categories}) async {
    try {
      await store.save<String>(WidgetKeys.categories, categories.join(','));
      await applyEnabled(enabled);
    } catch (_) {}
  }

  /// MY 토글만 바뀌었을 때
  Future<void> applyEnabled(bool enabled) async {
    try {
      await store.save<bool>(WidgetKeys.enabled, enabled);
      if (enabled) {
        await scheduler.start();
        await _fetchAndSave();
      } else {
        await scheduler.stop();
        await store.save<String>(WidgetKeys.state, WidgetStates.disabled);
        await store.redraw();
      }
    } catch (_) {}
  }

  /// 관심 카테고리만 바뀌었을 때 — 위젯이 켜져 있으면 바로 다시 불러온다
  Future<void> applyCategories(List<String> categories) async {
    try {
      await store.save<String>(WidgetKeys.categories, categories.join(','));
      if (await store.read<bool>(WidgetKeys.enabled) ?? false) await _fetchAndSave();
    } catch (_) {}
  }

  /// 앱 시작·주기 작업에서 호출. 마지막으로 반영된 토글·카테고리 기준으로 갱신한다.
  /// 반환값 false = 네트워크 실패 (주기 작업이 나중에 다시 시도하게)
  Future<bool> refresh() async {
    try {
      final enabled = await store.read<bool>(WidgetKeys.enabled) ?? false;
      if (!enabled) {
        await store.save<String>(WidgetKeys.state, WidgetStates.disabled);
        await store.redraw();
        return true;
      }
      return await _fetchAndSave();
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> _storedCategories() async {
    final csv = await store.read<String>(WidgetKeys.categories) ?? '';
    return csv.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  }

  /// 불러오기 실패 시엔 위젯에 이미 있는 뉴스를 그대로 둔다 (빈 화면으로 덮지 않음)
  Future<bool> _fetchAndSave() async {
    final List<WidgetNews> news;
    try {
      news = (await fetchNews(await _storedCategories())).take(maxWidgetCards).toList();
    } catch (_) {
      return false;
    }
    for (var i = 0; i < maxWidgetCards; i++) {
      final item = i < news.length ? news[i] : null;
      await store.save<String>(WidgetKeys.title(i), item?.title);
      await store.save<String>(WidgetKeys.badge(i), item?.category);
      await store.save<String>(WidgetKeys.articleId(i), item?.articleId.toString());
    }
    await store.save<int>(WidgetKeys.cardCount, news.length);
    await store.save<String>(
        WidgetKeys.state, news.isEmpty ? WidgetStates.empty : WidgetStates.ok);
    await store.redraw();
    return true;
  }
}

/// 위젯 줄을 눌러 앱이 열렸을 때의 링크 → 앱 화면 경로.
/// `newstory://article/7?style=card` → `/home/article/7?style=card`. 모르는 링크면 null(앱만 열기).
String? widgetUriToLocation(Uri? uri) {
  if (uri == null || uri.scheme != 'newstory' || uri.host != 'article') return null;
  if (uri.pathSegments.length != 1) return null;
  final id = int.tryParse(uri.pathSegments.single);
  if (id == null || id <= 0) return null;
  final style = uri.queryParameters['style'];
  const styles = {'card', 'fairy_tale', 'novel'};
  return styles.contains(style) ? '/home/article/$id?style=$style' : '/home/article/$id';
}
