import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/article.dart';
import '../home/article_repository.dart';

const searchPageSize = 20;
const maxKeywordLength = 50;
const searchDebounce = Duration(milliseconds: 300);

enum SearchStatus { idle, loading, loaded, error }

class SearchState {
  final String query;
  final String category;
  final SearchStatus status;
  final List<Article> articles;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  const SearchState({
    this.query = '',
    this.category = '전체',
    this.status = SearchStatus.idle,
    this.articles = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage + 1 < totalPages;

  SearchState copyWith({
    String? query,
    String? category,
    SearchStatus? status,
    List<Article>? articles,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) =>
      SearchState(
        query: query ?? this.query,
        category: category ?? this.category,
        status: status ?? this.status,
        articles: articles ?? this.articles,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// 제목 검색. 입력은 [searchDebounce] 동안 멈춰야 요청하고, 늦게 도착한 이전 요청의 응답은 버린다.
class SearchNotifier extends StateNotifier<SearchState> {
  final ArticleRepository _repo;
  final Duration debounce;
  Timer? _timer;

  /// 요청마다 1씩 올려서, 응답이 왔을 때 최신 요청이 아니면 무시한다.
  int _requestSeq = 0;

  SearchNotifier(this._repo, {this.debounce = searchDebounce}) : super(const SearchState());

  void setQuery(String query) {
    _timer?.cancel();
    state = state.copyWith(query: query);
    if (query.trim().isEmpty) {
      _requestSeq++;
      state = state.copyWith(status: SearchStatus.idle, articles: const [], isLoadingMore: false);
      return;
    }
    _timer = Timer(debounce, _search);
  }

  void setCategory(String category) {
    if (category == state.category) return;
    state = state.copyWith(category: category);
    if (state.query.trim().isEmpty) return;
    _timer?.cancel();
    _search();
  }

  Future<void> retry() => _search();

  Future<void> _search() async {
    final seq = ++_requestSeq;
    state = state.copyWith(
      status: SearchStatus.loading,
      articles: const [],
      currentPage: 0,
      isLoadingMore: false,
    );
    try {
      final result = await _repo.fetchArticles(
        page: 0,
        size: searchPageSize,
        category: state.category,
        keyword: state.query,
      );
      if (seq != _requestSeq || !mounted) return;
      state = state.copyWith(
        status: SearchStatus.loaded,
        articles: result.articles,
        totalPages: result.totalPages,
        currentPage: 0,
      );
    } catch (_) {
      if (seq != _requestSeq || !mounted) return;
      state = state.copyWith(status: SearchStatus.error);
    }
  }

  Future<void> loadMore() async {
    if (state.status != SearchStatus.loaded || !state.hasMore || state.isLoadingMore) return;
    final seq = _requestSeq;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.currentPage + 1;
      final result = await _repo.fetchArticles(
        page: next,
        size: searchPageSize,
        category: state.category,
        keyword: state.query,
      );
      if (seq != _requestSeq || !mounted) return;
      state = state.copyWith(
        articles: [...state.articles, ...result.articles],
        currentPage: next,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (_) {
      if (seq != _requestSeq || !mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref.watch(articleRepositoryProvider)),
);
