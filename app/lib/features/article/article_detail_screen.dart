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

const _levels = [
  (value: 'LOW', label: '쉬움', desc: '어려운 용어를 최대한 많이 풀어드려요'),
  (value: 'MEDIUM', label: '보통', desc: '적당히 설명해드려요'),
  (value: 'HIGH', label: '어려움', desc: '핵심 용어만 간단히 표시해요'),
];

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final int articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  // active tab: 'original' | 'fairy_tale' | 'novel' | 'card'
  String _tab = 'original';
  // style selected but not yet confirmed (null = no pending)
  String? _pendingStyle;
  String _pendingLevel = 'MEDIUM';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articleDetailProvider(widget.articleId).notifier).loadOriginal();
    });
  }

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
                    selected: _pendingStyle ?? _tab,
                    onSelected: (style) {
                      if (style == 'original') {
                        setState(() {
                          _tab = 'original';
                          _pendingStyle = null;
                        });
                      } else {
                        // already converted → just switch
                        final cached = state.cache.containsKey(style);
                        if (cached) {
                          setState(() {
                            _tab = style;
                            _pendingStyle = null;
                          });
                          notifier.selectStyle(style);
                        } else {
                          setState(() {
                            _pendingStyle = style;
                            _pendingLevel = 'MEDIUM';
                          });
                        }
                      }
                    },
                  ),
                  Expanded(child: _buildContent(context, state, notifier)),
                  _buildBottomBar(context, state, notifier),
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
    // 난이도 선택 대기 중
    if (_pendingStyle != null) {
      return _buildLevelPicker();
    }

    if (_tab == 'original') {
      if (state.isLoadingOriginal || (!state.isLoadingOriginal && state.originalContent == null && state.originalError == null)) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.originalError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.originalError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9A9CA3)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => notifier.loadOriginal(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
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
            Text(state.convertError!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9A9CA3))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => notifier.retryConvert(level: _pendingLevel),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final result = state.currentResult;
    if (result == null) return const SizedBox.shrink();

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

  Widget _buildLevelPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('난이도 선택',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17181C))),
          const SizedBox(height: 4),
          const Text('용어 설명의 양을 조절해요',
              style: TextStyle(fontSize: 13, color: Color(0xFF9A9CA3))),
          const SizedBox(height: 20),
          ..._levels.map((lv) {
            final isSelected = lv.value == _pendingLevel;
            return GestureDetector(
              onTap: () => setState(() => _pendingLevel = lv.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFECEAE4),
                    width: isSelected ? 2 : 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lv.label,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF17181C))),
                          const SizedBox(height: 2),
                          Text(lv.desc,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9A9CA3))),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFD8D4CC),
                          width: 1.6,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ArticleDetailState state,
    ArticleDetailNotifier notifier,
  ) {
    // 난이도 선택 중 → 확정 버튼
    if (_pendingStyle != null) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 22 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFECEAE4))),
        ),
        child: GestureDetector(
          onTap: () {
            final style = _pendingStyle!;
            setState(() {
              _tab = style;
              _pendingStyle = null;
            });
            notifier.selectStyle(style, level: _pendingLevel);
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '변환 시작',
              style: AppTextStyles.display(15).copyWith(color: Colors.white),
            ),
          ),
        ),
      );
    }

    // 일반 바 (원본 또는 변환 결과)
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
                  color: _tab == 'original'
                      ? const Color(0xFFECEAE4)
                      : btnColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(17, 17),
                      painter: BookmarkSavePainter(
                          _tab == 'original'
                              ? const Color(0xFF9A9CA3)
                              : Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '보관함에 저장',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _tab == 'original'
                              ? const Color(0xFF9A9CA3)
                              : Colors.white),
                    ),
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
                border:
                    Border.all(color: const Color(0xFFECEAE4), width: 1.4),
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
