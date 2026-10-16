import 'package:dio/dio.dart';

/// 홈스크린 위젯(Android)과 주고받는 키. 네이티브 `TodayCardsWidget.kt`가 같은 이름으로 읽는다.
class WidgetKeys {
  static const enabled = 'enabled';
  static const state = 'state';
  static const cardCount = 'card_count';
  static String title(int i) => 'card_${i}_title';
  static String time(int i) => 'card_${i}_time';
}

/// 위젯에 보여줄 상태: 카드 있음 / 서버에 카드요약 없음 / MY에서 꺼짐
class WidgetStates {
  static const ok = 'ok';
  static const empty = 'empty';
  static const disabled = 'disabled';
}

const maxWidgetCards = 3;

class TodayCard {
  final String title;
  final String readingTimeLabel;

  const TodayCard({required this.title, required this.readingTimeLabel});

  factory TodayCard.fromJson(Map<String, dynamic> json) => TodayCard(
        title: (json['title'] as String?) ?? '',
        readingTimeLabel: (json['readingTimeLabel'] as String?) ?? '',
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

typedef TodayCardsFetcher = Future<List<TodayCard>> Function();

/// `GET /api/widget/today-cards` — 로그인 없이 호출하는 공개 API라 인증 헤더 없는 Dio를 쓴다
TodayCardsFetcher todayCardsFetcher(Dio dio) => () async {
      final res = await dio.get('/api/widget/today-cards');
      final list = (res.data['data'] as List?) ?? const [];
      return list
          .map((e) => TodayCard.fromJson(e as Map<String, dynamic>))
          .toList();
    };

/// 위젯 데이터 갱신 로직. 플랫폼 코드와 분리해서 단위 테스트한다.
/// 위젯 쪽 실패가 앱 동작을 막으면 안 되니까 바깥으로 예외를 던지지 않는다.
class HomeWidgetService {
  final TodayCardsFetcher fetchCards;
  final WidgetStore store;
  final WidgetScheduler scheduler;

  HomeWidgetService({
    required this.fetchCards,
    required this.store,
    required this.scheduler,
  });

  /// MY 토글(서버 값)을 위젯에 반영. 켜면 바로 갱신하고 주기 갱신 시작, 끄면 안내 문구 + 주기 갱신 중단.
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

  /// 앱 시작·주기 작업에서 호출. 마지막으로 반영된 토글 값 기준으로 갱신한다.
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

  /// 불러오기 실패 시엔 위젯에 이미 있는 카드를 그대로 둔다 (빈 화면으로 덮지 않음)
  Future<bool> _fetchAndSave() async {
    final List<TodayCard> cards;
    try {
      cards = (await fetchCards()).take(maxWidgetCards).toList();
    } catch (_) {
      return false;
    }
    for (var i = 0; i < maxWidgetCards; i++) {
      final card = i < cards.length ? cards[i] : null;
      await store.save<String>(WidgetKeys.title(i), card?.title);
      await store.save<String>(WidgetKeys.time(i), card?.readingTimeLabel);
    }
    await store.save<int>(WidgetKeys.cardCount, cards.length);
    await store.save<String>(
        WidgetKeys.state, cards.isEmpty ? WidgetStates.empty : WidgetStates.ok);
    await store.redraw();
    return true;
  }
}
