import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'bookmarks_provider.dart';
import 'widgets/bookmark_card.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  int _tab = 0;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}월 ${dt.day}일';
    } catch (_) {
      return iso;
    }
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            Expanded(
              child: _tab == 0
                  ? _buildBookmarkGrid(state, notifier)
                  : _buildHistoryGrid(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkGrid(BookmarksState state, BookmarksNotifier notifier) {
    if (state.isLoadingBookmarks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.bookmarks.isEmpty) {
      return const _EmptyView(message: '저장된 보관함이 없습니다');
    }
    return RefreshIndicator(
      onRefresh: notifier.fetchBookmarks,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 100 + MediaQuery.of(context).padding.bottom),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.88,
        ),
        itemCount: state.bookmarks.length,
        itemBuilder: (context, index) {
          final item = state.bookmarks[index];
          return BookmarkCard(
            title: item.articleTitle,
            style: item.style,
            dateLabel: _formatDate(item.bookmarkedAt),
            onDelete: () => notifier.removeBookmark(item.resultId),
          );
        },
      ),
    );
  }

  Widget _buildHistoryGrid(BookmarksState state, BookmarksNotifier notifier) {
    if (state.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.history.isEmpty) {
      return const _EmptyView(message: '변환 기록이 없습니다');
    }
    return RefreshIndicator(
      onRefresh: notifier.fetchHistory,
      child: GridView.builder(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 100 + MediaQuery.of(context).padding.bottom),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.88,
        ),
        itemCount: state.history.length,
        itemBuilder: (context, index) {
          final item = state.history[index];
          return BookmarkCard(
            title: item.articleTitle,
            style: item.style,
            dateLabel: _formatDate(item.createdAt),
            onDelete: () => notifier.removeHistory(item.resultId),
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
