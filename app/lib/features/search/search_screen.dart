import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../home/widgets/article_list_tile.dart';
import '../home/widgets/category_chip_bar.dart';
import 'search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(searchProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    key: const Key('search-back'),
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CustomPaint(
                        size: const Size(22, 22),
                        painter: BackChevronPainter(AppColors.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildField(state, notifier)),
                ],
              ),
            ),
            CategoryChipBar(selected: state.category, onSelected: notifier.setCategory),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildField(SearchState state, SearchNotifier notifier) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E3DD)),
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(17, 17),
            painter: SearchIconPainter(const Color(0xFF9CA0A8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('search-field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              inputFormatters: [LengthLimitingTextInputFormatter(maxKeywordLength)],
              onChanged: notifier.setQuery,
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: '기사 제목 검색',
                hintStyle: TextStyle(color: Color(0xFF9CA0A8)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (state.query.isNotEmpty)
            IconButton(
              key: const Key('search-clear'),
              onPressed: _clear,
              icon: const Icon(Icons.cancel, size: 18, color: Color(0xFFB5B8BF)),
              tooltip: '지우기',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6E76)),
          ),
        ),
      );

  Widget _buildBody(SearchState state, SearchNotifier notifier) {
    switch (state.status) {
      case SearchStatus.idle:
        return _message('기사 제목으로 검색해보세요');
      case SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('검색하지 못했어요', style: TextStyle(color: Color(0xFF6B6E76))),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('search-retry'),
                onPressed: notifier.retry,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        );
      case SearchStatus.loaded:
        if (state.articles.isEmpty) {
          return _message("'${state.query.trim()}'에 맞는 기사가 없어요");
        }
        return ListView.separated(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(
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
        );
    }
  }
}
