import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
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
  // 'original' | 'fairy_tale' | 'novel' | 'card'
  String _tab = 'fairy_tale';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleDetailProvider(widget.articleId));
    final notifier = ref.read(articleDetailProvider(widget.articleId).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: state.isLoadingArticle
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(context, state),
                  StyleSegment(
                    selected: _tab,
                    onSelected: (tab) {
                      setState(() => _tab = tab);
                      if (tab == 'original') {
                        notifier.loadOriginal();
                      } else {
                        notifier.selectStyle(tab);
                      }
                    },
                  ),
                  Expanded(child: _buildContent(context, state, notifier)),
                  _buildBottomBar(context),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ArticleDetailState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: CustomPaint(
              size: const Size(22, 22),
              painter: BackChevronPainter(AppColors.ink),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _share(context),
            child: CustomPaint(
              size: const Size(20, 20),
              painter: ShareIconPainter(const Color(0xFF6B6E76)),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _saveToBookmarks(context),
            child: CustomPaint(
              size: const Size(20, 20),
              painter: BookmarkSavePainter(const Color(0xFF6B6E76)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ArticleDetailState state,
    ArticleDetailNotifier notifier,
  ) {
    if (_tab == 'original') {
      if (state.isLoadingOriginal) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.originalContent != null) {
        return OriginalTab(text: state.originalContent!);
      }
      return const SizedBox.shrink();
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
      return const SizedBox.shrink();
    }

    if (_tab == 'card') {
      return CardSummaryView(result: result);
    }

    return ConvertedTab(
      style: _tab,
      result: result,
      onShowGlossary: result.glossary.isNotEmpty
          ? () => GlossarySheet.show(context, result.glossary)
          : null,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isCard = _tab == 'card';
    final btnColor = isCard ? const Color(0xFF14B8A6) : AppColors.primary;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 22 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEAE4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _saveToBookmarks(context),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(17, 17),
                      painter: BookmarkSavePainter(Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text('보관함에 저장',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _share(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFECEAE4), width: 1.4),
              ),
              alignment: Alignment.center,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: ShareIconPainter(AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveToBookmarks(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('보관함 저장 기능은 곧 추가될 예정이에요'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _share(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능은 곧 추가될 예정이에요'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
