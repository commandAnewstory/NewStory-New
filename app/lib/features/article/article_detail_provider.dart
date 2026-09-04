import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../home/article_repository.dart';

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
  final String convertedText;
  final List<GlossaryItem> glossary;
  final String? readingTimeLabel;

  const ConvertResult({
    required this.convertedText,
    required this.glossary,
    this.readingTimeLabel,
  });
}

class ArticleDetailState {
  final String? articleUrl;
  final String? originalContent;
  final String? title;
  final bool isLoadingArticle;
  final String selectedStyle;
  final Map<String, ConvertResult> cache;
  final bool isConverting;
  final String? convertError;

  const ArticleDetailState({
    this.articleUrl,
    this.originalContent,
    this.title,
    this.isLoadingArticle = true,
    this.selectedStyle = 'fairy_tale',
    this.cache = const {},
    this.isConverting = false,
    this.convertError,
  });

  ConvertResult? get currentResult => cache[selectedStyle];

  ArticleDetailState copyWith({
    String? articleUrl,
    String? originalContent,
    String? title,
    bool? isLoadingArticle,
    String? selectedStyle,
    Map<String, ConvertResult>? cache,
    bool? isConverting,
    String? convertError,
  }) {
    return ArticleDetailState(
      articleUrl: articleUrl ?? this.articleUrl,
      originalContent: originalContent ?? this.originalContent,
      title: title ?? this.title,
      isLoadingArticle: isLoadingArticle ?? this.isLoadingArticle,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      cache: cache ?? this.cache,
      isConverting: isConverting ?? this.isConverting,
      convertError: convertError,
    );
  }
}

class ArticleDetailNotifier extends StateNotifier<ArticleDetailState> {
  final Dio _dio;
  final ArticleRepository _repo;
  final int articleId;

  ArticleDetailNotifier(this._dio, this._repo, this.articleId)
      : super(const ArticleDetailState()) {
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      final article = await _repo.fetchArticleById(articleId);
      state = state.copyWith(
        title: article.title,
        articleUrl: article.url,
        isLoadingArticle: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingArticle: false);
    }
  }

  Future<void> selectStyle(String style) async {
    if (state.selectedStyle == style) return;
    state = state.copyWith(selectedStyle: style, convertError: null);
    if (!state.cache.containsKey(style)) {
      await _convert(style);
    }
  }

  Future<void> retryConvert() async {
    await _convert(state.selectedStyle);
  }

  Future<void> _convert(String style) async {
    final url = state.articleUrl;
    if (url == null) return;

    state = state.copyWith(isConverting: true, convertError: null);
    try {
      final response = await _dio.post('/api/convert', data: {
        'url': url,
        'style': style,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final glossaryRaw = data['glossary'] as List<dynamic>? ?? [];
      final result = ConvertResult(
        convertedText: data['convertedText'] as String,
        glossary: glossaryRaw
            .map((e) => GlossaryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        readingTimeLabel: data['readingTimeLabel'] as String?,
      );
      final newCache = Map<String, ConvertResult>.from(state.cache)
        ..[style] = result;
      state = state.copyWith(cache: newCache, isConverting: false);
    } catch (e) {
      state = state.copyWith(
          isConverting: false, convertError: '변환에 실패했습니다. 다시 시도해 주세요.');
    }
  }
}

final articleDetailProvider = StateNotifierProvider.family<
    ArticleDetailNotifier, ArticleDetailState, int>(
  (ref, articleId) => ArticleDetailNotifier(
    ref.watch(dioProvider),
    ref.watch(articleRepositoryProvider),
    articleId,
  ),
);
