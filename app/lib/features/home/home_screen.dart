import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'home_provider.dart';
import 'widgets/category_chip_bar.dart';
import 'widgets/article_list_tile.dart';

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

    return RefreshIndicator(
      onRefresh: () => ref.read(homeProvider.notifier).fetchInitial(),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, i) => const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Color(0xFFF0EDE8),
        ),
        itemBuilder: (context, index) {
          if (index >= state.articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final article = state.articles[index];
          return ArticleListTile(
            article: article,
            onTap: () => context.push('/home/article/${article.id}'),
          );
        },
      ),
    );
  }
}
