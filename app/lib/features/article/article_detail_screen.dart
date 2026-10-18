import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/launch/url_opener.dart';
import '../../core/router/app_router.dart';
import '../../core/share/share_text.dart';
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

  /// 위젯에서 들어올 때 바로 열 변환 스타일 (예: 'card'). null이면 원문 탭
  final String? initialStyle;

  const ArticleDetailScreen({super.key, required this.articleId, this.initialStyle});

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
    final style = widget.initialStyle;
    if (style == 'fairy_tale' || style == 'novel' || style == 'card') _tab = style!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(articleDetailProvider(widget.articleId).notifier);
      notifier.loadOriginal();
      if (_tab != 'original') notifier.openWithStyle(_tab);
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
                    busy: state.converting,
                    onSelected: (style) {
                      if (style == 'original') {
                        setState(() {
                          _tab = 'original';
                          _pendingStyle = null;
                        });
                      } else {
                        // 이미 변환됐거나 생성 중이면 난이도 다시 묻지 않고 그 탭으로 이동만
                        final cached = state.cache.containsKey(style) ||
                            state.converting.contains(style);
                        if (cached) {
                          setState(() {
                            _tab = style;
                            _pendingStyle = null;
                          });
                          notifier.selectStyle(style);
                        } else {
                          setState(() {
                            _pendingStyle = style;
                            _pendingLevel = state.defaultLevel;
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
            onTap: () => _share(context, state),
            child: CustomPaint(
              size: const Size(20, 20),
              painter: ShareIconPainter(const Color(0xFF6B6E76)),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _toggleBookmark(context, state),
            child: CustomPaint(
              size: const Size(20, 20),
              painter: BookmarkSavePainter(
                _canBookmark(state)
                    ? (_isBookmarked(state) ? AppColors.primary : const Color(0xFF6B6E76))
                    : const Color(0xFFD8D4CC),
                filled: _isBookmarked(state),
              ),
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
        return _errorView(state, state.originalError!, notifier.loadOriginal);
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
      return _errorView(
          state, state.convertError!, () => notifier.retryConvert(level: _pendingLevel));
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

  /// 원문·변환 실패 공통 화면: 안내 문구 + 다시 시도 + 원문 사이트에서 보기(외부 브라우저)
  Widget _errorView(ArticleDetailState state, String message, VoidCallback onRetry) {
    final url = state.articleUrl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9A9CA3)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  key: const Key('error-retry'),
                  onPressed: onRetry,
                  child: const Text('다시 시도'),
                ),
                if (url != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('open-original-site'),
                    onPressed: () => _openOriginal(context, url),
                    child: const Text('원문 사이트에서 보기'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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

  /// 크롤링해 온 기사 원본 링크를 외부 브라우저로 연다
  Future<void> _openOriginal(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ref.read(urlOpenerProvider)(url);
    if (!opened) {
      messenger.showSnackBar(const SnackBar(
        content: Text('원문 링크를 열 수 없어요.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
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
              key: const Key('bookmark-toggle'),
              onTap: () => _toggleBookmark(context, state),
              child: Builder(builder: (context) {
                final enabled = _canBookmark(state);
                final saved = _isBookmarked(state);
                final fg = !enabled
                    ? const Color(0xFF9A9CA3)
                    : saved
                        ? btnColor
                        : Colors.white;
                return Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: !enabled
                        ? const Color(0xFFECEAE4)
                        : saved
                            ? Colors.white
                            : btnColor,
                    borderRadius: BorderRadius.circular(14),
                    border: saved && enabled
                        ? Border.all(color: btnColor, width: 1.4)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(17, 17),
                        painter: BookmarkSavePainter(fg, filled: saved),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        saved ? '저장됨' : '보관함에 저장',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: fg),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (state.articleUrl != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('open-original'),
              onTap: () => _openOriginal(context, state.articleUrl!),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECEAE4), width: 1.4),
                ),
                alignment: Alignment.center,
                child: const Text('원문 보기',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ),
          ],
          const SizedBox(width: 10),
          GestureDetector(
            key: const Key('share-button'),
            onTap: () => _share(context, state),
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

  /// 변환 탭에서 변환 결과가 있을 때만 저장 가능 (원문 탭엔 저장할 결과가 없음)
  bool _canBookmark(ArticleDetailState state) =>
      _tab != 'original' &&
      _pendingStyle == null &&
      state.currentResult?.resultId != null;

  bool _isBookmarked(ArticleDetailState state) =>
      _canBookmark(state) && state.currentResult!.bookmarked;

  Future<void> _toggleBookmark(
      BuildContext context, ArticleDetailState state) async {
    if (!_canBookmark(state) || state.isTogglingBookmark) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(articleDetailProvider(widget.articleId).notifier)
        .toggleBookmark();
    if (!ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('보관함 저장에 실패했어요. 다시 시도해 주세요.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _share(BuildContext context, ArticleDetailState state) async {
    final url = state.articleUrl;
    if (url == null) return;
    final result = _tab == 'original' ? null : state.currentResult;
    final text = buildShareText(
      title: state.title ?? '',
      url: url,
      style: result == null ? 'original' : _tab,
      convertedText: result?.convertedText,
    );
    await ref.read(shareLauncherProvider)(text, subject: state.title);
  }
}
