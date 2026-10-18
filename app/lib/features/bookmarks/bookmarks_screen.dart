import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'bookmarks_provider.dart';
import 'saved_result_provider.dart';
import '../../core/router/app_router.dart';
import '../home/widgets/category_chip_bar.dart';
import 'saved_filter.dart';
import 'widgets/saved_list_tile.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  int _tab = 0;
  final _searchController = TextEditingController();

  /// 보관함/히스토리를 오가도 유지되는 검색어·필터
  SavedFilter _filter = const SavedFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    _searchController.clear();
    setState(() => _filter = const SavedFilter());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarksProvider);
    final notifier = ref.read(bookmarksProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Text('보관함', style: AppTextStyles.display(21)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _FlatTab(
                      label: '보관함',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: 4),
                  _FlatTab(
                      label: '히스토리',
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _buildSearchField(),
            ),
            CategoryChipBar(
              selected: _filter.category,
              onSelected: (c) => setState(() => _filter = _filter.copyWith(category: c)),
            ),
            const SizedBox(height: 8),
            SavedStyleFilterBar(
              selected: _filter.style,
              onSelected: (s) => setState(() => _filter = _filter.copyWith(style: s)),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _tab == 0
                  ? _buildList(
                      loading: state.isLoadingBookmarks,
                      entries: state.bookmarks.map(SavedEntry.fromBookmark).toList(),
                      emptyMessage: '저장된 보관함이 없습니다',
                      onRefresh: notifier.fetchBookmarks,
                      onDelete: notifier.removeBookmark,
                    )
                  : _buildList(
                      loading: state.isLoadingHistory,
                      entries: state.history.map(SavedEntry.fromHistory).toList(),
                      emptyMessage: '변환 기록이 없습니다',
                      onRefresh: notifier.fetchHistory,
                      onDelete: notifier.removeHistory,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E3DD)),
      ),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(16, 16),
            painter: SearchIconPainter(const Color(0xFF9CA0A8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('saved-search'),
              controller: _searchController,
              onChanged: (q) => setState(() => _filter = _filter.copyWith(query: q)),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: '기사 제목으로 찾기',
                hintStyle: TextStyle(color: Color(0xFF9CA0A8)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_filter.query.isNotEmpty)
            IconButton(
              key: const Key('saved-search-clear'),
              onPressed: () {
                _searchController.clear();
                setState(() => _filter = _filter.copyWith(query: ''));
              },
              icon: const Icon(Icons.cancel, size: 17, color: Color(0xFFB5B8BF)),
              tooltip: '지우기',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildList({
    required bool loading,
    required List<SavedEntry> entries,
    required String emptyMessage,
    required Future<void> Function() onRefresh,
    required Future<void> Function(int resultId) onDelete,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (entries.isEmpty) return _EmptyView(message: emptyMessage);

    final visible = _filter.apply(entries);
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('조건에 맞는 항목이 없어요',
                style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('saved-filter-reset'),
              onPressed: _resetFilter,
              child: const Text('필터 초기화'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: 100 + MediaQuery.of(context).padding.bottom),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Color(0xFFF0EDE8),
        ),
        itemBuilder: (context, index) {
          final e = visible[index];
          return SavedListTile(
            entry: e,
            onDelete: () => onDelete(e.resultId),
            onTap: () => context.push('/bookmarks/result/${e.resultId}',
                extra: SavedResultArgs(title: e.title, style: e.style, articleUrl: e.articleUrl)),
          );
        },
      ),
    );
  }
}

class _FlatTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FlatTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF17181C) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : const Color(0xFF9A9CA3),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
    );
  }
}
