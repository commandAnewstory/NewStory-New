import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'article.dart';
import 'article_repository.dart';

const _pageSize = 20;

class HomeState {
  final String selectedCategory;
  final List<Article> articles;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const HomeState({
    this.selectedCategory = '전체',
    this.articles = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage + 1 < totalPages;

  HomeState copyWith({
    String? selectedCategory,
    List<Article>? articles,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return HomeState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      articles: articles ?? this.articles,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ArticleRepository _repo;

  HomeNotifier(this._repo) : super(const HomeState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, articles: [], currentPage: 0);
    try {
      final result = await _repo.fetchArticles(
        page: 0,
        size: _pageSize,
        category: state.selectedCategory,
      );
      state = state.copyWith(
        articles: result.articles,
        totalPages: result.totalPages,
        currentPage: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.fetchArticles(
        page: nextPage,
        size: _pageSize,
        category: state.selectedCategory,
      );
      state = state.copyWith(
        articles: [...state.articles, ...result.articles],
        currentPage: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> selectCategory(String category) async {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    await fetchInitial();
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(ref.watch(articleRepositoryProvider)),
);
