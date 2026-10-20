import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/bookmark/bookmark_api.dart';
import '../../core/convert/convert_jobs.dart';
import '../home/article_repository.dart';

const contentUnavailableMessage = '기사 본문을 가져오지 못했어요. 원문 사이트에서 확인해 주세요.';

class GlossaryItem {
  final String term;
  final String definition;
  const GlossaryItem({required this.term, required this.definition});

  factory GlossaryItem.fromJson(Map<String, dynamic> json) => GlossaryItem(
        term: json['term'] as String,
        definition: json['definition'] as String,
      );
}

class ConvertResult {
  final int? resultId;
  final String convertedText;
  final List<GlossaryItem> glossary;
  final String? readingTimeLabel;
  final bool bookmarked;

  const ConvertResult({
    this.resultId,
    required this.convertedText,
    required this.glossary,
    this.readingTimeLabel,
    this.bookmarked = false,
  });

  factory ConvertResult.fromJson(Map<String, dynamic> data) => ConvertResult(
        resultId: data['id'] as int?,
        convertedText: data['convertedText'] as String,
        glossary: (data['glossary'] as List<dynamic>? ?? [])
            .map((e) => GlossaryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        readingTimeLabel: data['readingTimeLabel'] as String?,
        bookmarked: data['bookmarked'] as bool? ?? false,
      );

  ConvertResult copyWith({bool? bookmarked}) => ConvertResult(
        resultId: resultId,
        convertedText: convertedText,
        glossary: glossary,
        readingTimeLabel: readingTimeLabel,
        bookmarked: bookmarked ?? this.bookmarked,
      );
}

class ArticleDetailState {
  final String? articleUrl;
  final String? originalContent;
  final bool isLoadingOriginal;
  final String? originalError;
  final String? title;
  final bool isLoadingArticle;
  final String selectedStyle;
  final Map<String, ConvertResult> cache;
  /// 지금 생성 중인 스타일들. 스타일마다 따로 돌아서, 생성 중에 다른 탭을 봐도 끊기지 않는다.
  final Set<String> converting;

  /// 스타일별 마지막 생성 실패 문구
  final Map<String, String> convertErrors;

  /// 보관함 저장/취소 요청 중 (연타 방지)
  final bool isTogglingBookmark;

  /// 레벨 선택 기본값 — 사용자가 마지막으로 고른 레벨 (서버 `lastGlossaryLevel`)
  final String defaultLevel;

  /// 화면에서 마지막으로 보고 있던 탭('original' | 스타일). 뒤로 갔다가 다시 들어오면 이 탭으로 연다.
  final String lastTab;

  const ArticleDetailState({
    this.articleUrl,
    this.originalContent,
    this.isLoadingOriginal = false,
    this.originalError,
    this.title,
    this.isLoadingArticle = true,
    this.selectedStyle = 'fairy_tale',
    this.cache = const {},
    this.converting = const {},
    this.convertErrors = const {},
    this.defaultLevel = 'MEDIUM',
    this.isTogglingBookmark = false,
    this.lastTab = 'original',
  });

  ConvertResult? get currentResult => cache[selectedStyle];

  /// 지금 보고 있는 스타일이 생성 중인지
  bool get isConverting => converting.contains(selectedStyle);

  String? get convertError => convertErrors[selectedStyle];

  /// 이 스타일에 대해 보여줄 게 있는지 (결과·생성 중·실패) — 없으면 난이도부터 고른다
  bool hasActivity(String style) =>
      cache.containsKey(style) || converting.contains(style) || convertErrors.containsKey(style);

  ArticleDetailState copyWith({
    String? articleUrl,
    String? originalContent,
    bool? isLoadingOriginal,
    String? originalError,
    String? title,
    bool? isLoadingArticle,
    String? selectedStyle,
    Map<String, ConvertResult>? cache,
    Set<String>? converting,
    Map<String, String>? convertErrors,
    String? defaultLevel,
    bool? isTogglingBookmark,
    String? lastTab,
  }) {
    return ArticleDetailState(
      articleUrl: articleUrl ?? this.articleUrl,
      originalContent: originalContent ?? this.originalContent,
      isLoadingOriginal: isLoadingOriginal ?? this.isLoadingOriginal,
      originalError: originalError,
      title: title ?? this.title,
      isLoadingArticle: isLoadingArticle ?? this.isLoadingArticle,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      cache: cache ?? this.cache,
      converting: converting ?? this.converting,
      convertErrors: convertErrors ?? this.convertErrors,
      defaultLevel: defaultLevel ?? this.defaultLevel,
      isTogglingBookmark: isTogglingBookmark ?? this.isTogglingBookmark,
      lastTab: lastTab ?? this.lastTab,
    );
  }
}

class ArticleDetailNotifier extends StateNotifier<ArticleDetailState> {
  final Dio _dio;
  final ArticleRepository _repo;
  final BookmarkApi _bookmarks;
  final int articleId;

  /// 화면 밖 플로팅 버튼용 전역 작업 목록 (테스트에선 없을 수 있음)
  final ConvertJobsNotifier? jobs;

  /// 기사 URL을 알게 되면(성공·실패 모두) 끝나는 신호 — 위젯에서 바로 변환하려고 열 때 기다린다
  final _articleReady = Completer<void>();
  late final Future<void> _levelLoaded;

  ArticleDetailNotifier(this._dio, this._repo, this._bookmarks, this.articleId,
      {this.jobs})
      : super(const ArticleDetailState()) {
    _loadArticle();
    _levelLoaded = _loadDefaultLevel();
  }

  /// 위젯 "관심 뉴스"에서 눌러 들어온 경우: 난이도를 묻지 않고 사용자 기본 난이도로 바로 [style] 변환 시작.
  /// 기사·기본 난이도를 아직 불러오는 중이면 끝날 때까지 기다렸다가 시작한다.
  Future<void> openWithStyle(String style) async {
    state = state.copyWith(selectedStyle: style, lastTab: style);
    if (state.cache.containsKey(style) || state.converting.contains(style)) return;
    // 기사·난이도를 기다리는 동안에도 화면엔 "만드는 중"이 보이게 먼저 생성 중으로 표시
    state = state.copyWith(
      converting: {...state.converting, style},
      convertErrors: Map.of(state.convertErrors)..remove(style),
    );
    await Future.wait([_articleReady.future, _levelLoaded]);
    if (!mounted) return;
    if (state.articleUrl == null) {
      state = state.copyWith(
        converting: {...state.converting}..remove(style),
        convertErrors: Map.of(state.convertErrors)..[style] = '기사를 불러오지 못했어요. 다시 시도해 주세요.',
      );
      return;
    }
    await _convert(style, level: state.defaultLevel, reserved: true);
  }

  /// 화면 탭이 바뀔 때 — 다시 들어왔을 때 같은 탭을 열고, 저장/공유가 보고 있는 스타일 기준으로 동작하게
  void setTab(String tab) {
    state = tab == 'original'
        ? state.copyWith(lastTab: tab)
        : state.copyWith(lastTab: tab, selectedStyle: tab);
  }

  Future<void> _loadDefaultLevel() async {
    try {
      final res = await _dio.get('/api/users/me');
      final data = res.data['data'] as Map<String, dynamic>;
      final level = data['lastGlossaryLevel'] as String?;
      if (level != null && mounted) state = state.copyWith(defaultLevel: level);
    } catch (_) {}
  }

  /// 조회수 기록 — 실패해도 화면엔 영향 없음
  Future<void> _recordView() async {
    try {
      await _dio.post('/api/news/$articleId/view');
    } catch (_) {}
  }

  Future<void> _loadArticle() async {
    if (await _fetchArticle()) {
      _recordView();
      // trigger immediately now that url is known (avoids postFrameCallback race)
      await loadOriginal();
    }
  }

  /// 기사 제목·URL 조회. 성공하면 true
  Future<bool> _fetchArticle() async {
    try {
      final article = await _repo.fetchArticleById(articleId);
      if (!mounted) return false;
      state = state.copyWith(
        title: article.title,
        articleUrl: article.url,
        isLoadingArticle: false,
      );
      return true;
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingArticle: false);
      return false;
    } finally {
      if (!_articleReady.isCompleted) _articleReady.complete();
    }
  }

  Future<void> loadOriginal() async {
    final url = state.articleUrl;
    if (url == null || state.originalContent != null || state.isLoadingOriginal) return;
    state = state.copyWith(isLoadingOriginal: true, originalError: null);
    try {
      final res = await _dio.get('/api/convert/original', queryParameters: {'url': url});
      final data = res.data['data'] as Map<String, dynamic>;
      final content = (data['content'] as String? ?? '').trim();
      if (content.isEmpty) {
        // 본문을 못 뽑은 기사 — 빈 화면 대신 안내 + 원문 사이트 버튼
        state = state.copyWith(isLoadingOriginal: false, originalError: contentUnavailableMessage);
        return;
      }
      state = state.copyWith(originalContent: content, isLoadingOriginal: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingOriginal: false,
        originalError: _serverMessageIfUnavailable(e) ??
            '원문을 불러오지 못했어요.\n네트워크 연결을 확인하고 다시 시도해 주세요.',
      );
    }
  }

  Future<void> selectStyle(String style, {String level = 'MEDIUM'}) async {
    state = state.copyWith(selectedStyle: style);
    if (!state.cache.containsKey(style) && !state.converting.contains(style)) {
      await _convert(style, level: level);
    }
  }

  Future<void> retryConvert({String? level}) async {
    if (state.articleUrl == null && !await _fetchArticle()) return; // 기사 자체를 못 불러온 경우 — 기사부터 다시
    await _convert(state.selectedStyle, level: level ?? state.defaultLevel);
  }

  /// [reserved] = 호출한 쪽이 이미 생성 중으로 표시해 둠 (위젯 진입)
  Future<void> _convert(String style, {String level = 'MEDIUM', bool reserved = false}) async {
    final url = state.articleUrl;
    if (url == null) {
      if (reserved) state = state.copyWith(converting: {...state.converting}..remove(style));
      return;
    }
    if (!reserved && state.converting.contains(style)) return;

    state = state.copyWith(
      converting: {...state.converting, style},
      convertErrors: Map.of(state.convertErrors)..remove(style),
    );
    jobs?.start(articleId, style, state.title ?? '기사');
    try {
      final response = await _dio.post('/api/convert', data: {
        'url': url,
        'style': style,
        'level': level,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final result = ConvertResult.fromJson(data);
      jobs?.finish(articleId, style, success: true);
      if (!mounted) return;
      // await 동안 다른 스타일 생성이 끝났을 수 있으니 항상 최신 state 기준으로 합친다
      state = state.copyWith(
        cache: Map.of(state.cache)..[style] = result,
        converting: {...state.converting}..remove(style),
        defaultLevel: level,
      );
    } catch (e) {
      jobs?.finish(articleId, style, success: false);
      if (!mounted) return;
      state = state.copyWith(
        converting: {...state.converting}..remove(style),
        convertErrors: Map.of(state.convertErrors)
          ..[style] = _serverMessageIfUnavailable(e) ?? '변환에 실패했습니다. 다시 시도해 주세요.',
      );
    }
  }

  /// 서버가 "본문을 못 가져옴"(502)으로 실패시킨 경우 그 안내 문구. 다른 실패면 null.
  String? _serverMessageIfUnavailable(Object e) {
    if (e is DioException && e.response?.statusCode == 502) {
      final body = e.response?.data;
      final msg = body is Map ? body['message'] as String? : null;
      return (msg == null || msg.isEmpty) ? contentUnavailableMessage : msg;
    }
    return null;
  }

  /// 현재 보고 있는 변환 결과의 보관함 저장 ↔ 취소. 성공하면 true.
  /// 요청 중엔 무시하고, 실패하면 원래 상태 그대로 두고 false.
  Future<bool> toggleBookmark() async {
    final style = state.selectedStyle;
    final current = state.cache[style];
    if (current?.resultId == null || state.isTogglingBookmark) return false;

    state = state.copyWith(isTogglingBookmark: true);
    try {
      final bookmarked = await _bookmarks.toggle(current!.resultId!,
          currentlyBookmarked: current.bookmarked);
      final newCache = Map<String, ConvertResult>.from(state.cache)
        ..[style] = current.copyWith(bookmarked: bookmarked);
      state = state.copyWith(cache: newCache, isTogglingBookmark: false);
      return true;
    } catch (_) {
      state = state.copyWith(isTogglingBookmark: false);
      return false;
    }
  }
}

final articleDetailProvider = StateNotifierProvider.family<
    ArticleDetailNotifier, ArticleDetailState, int>(
  (ref, articleId) => ArticleDetailNotifier(
    ref.watch(dioProvider),
    ref.watch(articleRepositoryProvider),
    ref.watch(bookmarkApiProvider),
    articleId,
    jobs: ref.read(convertJobsProvider.notifier),
  ),
);
