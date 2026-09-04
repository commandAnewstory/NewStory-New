import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'article_detail_provider.dart';
import 'widgets/style_segment.dart';
import 'widgets/original_tab.dart';
import 'widgets/converted_tab.dart';
import 'widgets/card_summary_view.dart';
import 'widgets/glossary_sheet.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final int articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleDetailProvider(widget.articleId));
    final notifier = ref.read(articleDetailProvider(widget.articleId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: state.isLoadingArticle
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                StyleSegment(
                  selected: state.selectedStyle,
                  onSelected: (style) {
                    setState(() => _showOriginal = false);
                    notifier.selectStyle(style);
                  },
                ),
                if (state.selectedStyle != 'card')
                  _OriginalConvertedToggle(
                    showOriginal: _showOriginal,
                    onToggle: (v) => setState(() => _showOriginal = v),
                  ),
                Expanded(child: _buildContent(context, state, notifier)),
              ],
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ArticleDetailState state,
    ArticleDetailNotifier notifier,
  ) {
    if (_showOriginal && state.originalContent != null) {
      return OriginalTab(text: state.originalContent!);
    }

    if (state.isConverting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.convertError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.convertError!),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.retryConvert,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final result = state.currentResult;
    if (result == null) {
      if (state.originalContent != null) {
        return OriginalTab(text: state.originalContent!);
      }
      return const SizedBox.shrink();
    }

    if (state.selectedStyle == 'card') {
      return CardSummaryView(result: result);
    }

    return ConvertedTab(
      style: state.selectedStyle,
      result: result,
      onShowGlossary: result.glossary.isNotEmpty
          ? () => GlossarySheet.show(context, result.glossary)
          : null,
    );
  }
}

class _OriginalConvertedToggle extends StatelessWidget {
  final bool showOriginal;
  final ValueChanged<bool> onToggle;

  const _OriginalConvertedToggle({
    required this.showOriginal,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _Tab(label: '변환', selected: !showOriginal, onTap: () => onToggle(false)),
          const SizedBox(width: 8),
          _Tab(label: '원문', selected: showOriginal, onTap: () => onToggle(true)),
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
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF8E8E93),
          decoration: selected ? TextDecoration.underline : TextDecoration.none,
          decorationColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
