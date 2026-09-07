import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            CategoryChipBar(
              selected: state.selectedCategory,
              onSelected: (cat) =>
                  ref.read(homeProvider.notifier).selectCategory(cat),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('NewStory', style: AppTextStyles.display(21)),
          Row(
            children: [
              CustomPaint(
                size: const Size(20, 20),
                painter: SearchIconPainter(const Color(0xFF6B6E76)),
              ),
              const SizedBox(width: 16),
              CustomPaint(
                size: const Size(20, 20),
                painter: BellIconPainter(const Color(0xFF6B6E76)),
              ),
            ],
          ),
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
              onTap: () => context.push('/home/article/${hero.id}'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('최신 뉴스', style: AppTextStyles.display(16)),
                  const Text('더보기',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9A9CA3))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= gridItems.length) return null;
                  final article = gridItems[index];
                  return ArticleGridCard(
                    article: article,
                    onTap: () => context.push('/home/article/${article.id}'),
                  );
                },
                childCount: gridItems.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
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
}
