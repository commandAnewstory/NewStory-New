import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bookmarks_provider.dart';
import 'widgets/result_list_item.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  int _selectedIndex = 0;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarksProvider);
    final notifier = ref.read(bookmarksProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('보관함',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _SegmentControl(
            selected: _selectedIndex,
            onChanged: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildBookmarks(state, notifier)
                : _buildHistory(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarks(BookmarksState state, BookmarksNotifier notifier) {
    if (state.isLoadingBookmarks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.bookmarks.isEmpty) {
      return const _EmptyView(message: '저장된 보관함이 없습니다');
    }
    return RefreshIndicator(
      onRefresh: notifier.fetchBookmarks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.bookmarks.length,
        itemBuilder: (context, index) {
          final item = state.bookmarks[index];
          return ResultListItem(
            title: item.articleTitle,
            style: item.style,
            dateLabel: _formatDate(item.bookmarkedAt),
            onDelete: () => notifier.removeBookmark(item.resultId),
          );
        },
      ),
    );
  }

  Widget _buildHistory(BookmarksState state, BookmarksNotifier notifier) {
    if (state.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.history.isEmpty) {
      return const _EmptyView(message: '변환 기록이 없습니다');
    }
    return RefreshIndicator(
      onRefresh: notifier.fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.history.length,
        itemBuilder: (context, index) {
          final item = state.history[index];
          return ResultListItem(
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

class _SegmentControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _Tab(label: '보관함', selected: selected == 0, onTap: () => onChanged(0)),
          _Tab(label: '히스토리', selected: selected == 1, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? const Color(0xFF17181C) : const Color(0xFF8E8E93),
            ),
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
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
      ),
    );
  }
}
