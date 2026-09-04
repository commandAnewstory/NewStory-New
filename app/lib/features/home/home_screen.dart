import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_provider.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/hero_card.dart';
import 'widgets/article_grid_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(homeProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NewStory',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          CategoryChipBar(
            selected: state.selectedCategory,
            onSelected: (cat) =>
                ref.read(homeProvider.notifier).selectCategory(cat),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(HomeState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('뉴스를 불러오지 못했습니다'),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(homeProvider.notifier).fetchInitial(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (state.articles.isEmpty) {
      return const Center(child: Text('기사가 없습니다'));
    }

    final hero = state.articles.first;
    final gridItems = state.articles.skip(1).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).fetchInitial(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: HeroCard(
              article: hero,
              onTap: () => _navigateToDetail(hero.id),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= gridItems.length) return null;
                  final article = gridItems[index];
                  return ArticleGridCard(
                    article: article,
                    onTap: () => _navigateToDetail(article.id),
                  );
                },
                childCount: gridItems.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
            ),
          ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(int articleId) {
    context.push('/home/article/$articleId');
  }
}
