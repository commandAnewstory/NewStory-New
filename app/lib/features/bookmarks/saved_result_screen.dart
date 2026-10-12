import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/launch/url_opener.dart';
import '../../core/router/app_router.dart';
import '../../core/share/share_text.dart';
import '../../core/theme/app_theme.dart';
import '../article/widgets/card_summary_view.dart';
import '../article/widgets/converted_tab.dart';
import '../article/widgets/glossary_sheet.dart';
import 'saved_result_provider.dart';

const _styleLabels = {'fairy_tale': '동화체', 'novel': '소설체', 'card': '카드요약'};
const _styleBg = {
  'fairy_tale': Color(0xFFFDECC8),
  'novel': Color(0xFFE6DEFA),
  'card': Color(0xFFD7F3EE),
};
const _styleText = {
  'fairy_tale': Color(0xFF8A5A0F),
  'novel': Color(0xFF5A3A9E),
  'card': Color(0xFF0B6E64),
};

/// 보관함·히스토리에서 연 저장된 변환 결과 (2026-10-12, 서브플랜 앱 12)
class SavedResultScreen extends ConsumerWidget {
  final int resultId;
  final SavedResultArgs args;

  const SavedResultScreen({super.key, required this.resultId, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedResultProvider(resultId));
    final notifier = ref.read(savedResultProvider(resultId).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(args: args),
            Expanded(child: _buildBody(context, state, notifier)),
            if (state.result != null) _BottomBar(resultId: resultId, args: args),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, SavedResultState state, SavedResultNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null || state.result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error ?? '결과가 없어요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9A9CA3))),
              const SizedBox(height: 16),
              TextButton(onPressed: notifier.load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    final result = state.result!;
    if (args.style == 'card') {
      return CardSummaryView(result: result);
    }
    return ConvertedTab(
      style: args.style,
      result: result,
      onShowGlossary: result.glossary.isNotEmpty
          ? () => GlossarySheet.show(context, result.glossary)
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  final SavedResultArgs args;

  const _Header({required this.args});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: CustomPaint(
              size: const Size(22, 22),
              painter: BackChevronPainter(AppColors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _styleBg[args.style] ?? const Color(0xFFE8ECFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _styleLabels[args.style] ?? args.style,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _styleText[args.style] ?? AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  args.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final int resultId;
  final SavedResultArgs args;

  const _BottomBar({required this.resultId, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedResultProvider(resultId));
    final result = state.result!;
    final saved = result.bookmarked;
    final url = args.articleUrl;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 22 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEAE4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('saved-bookmark-toggle'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok =
                    await ref.read(savedResultProvider(resultId).notifier).toggleBookmark();
                if (!ok) {
                  messenger.showSnackBar(const SnackBar(
                    content: Text('보관함 저장에 실패했어요. 다시 시도해 주세요.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: saved ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: saved ? Border.all(color: AppColors.primary, width: 1.4) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(17, 17),
                      painter: BookmarkSavePainter(
                          saved ? AppColors.primary : Colors.white,
                          filled: saved),
                    ),
                    const SizedBox(width: 8),
                    Text(saved ? '저장됨' : '보관함에 저장',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: saved ? AppColors.primary : Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          if (url != null) ...[
            const SizedBox(width: 10),
            _OutlinedSquare(
              key: const Key('saved-open-original'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final opened = await ref.read(urlOpenerProvider)(url);
                if (!opened) {
                  messenger.showSnackBar(const SnackBar(
                    content: Text('원문 링크를 열 수 없어요.'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: const Text('원문',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            const SizedBox(width: 10),
            _OutlinedSquare(
              key: const Key('saved-share'),
              onTap: () => ref.read(shareLauncherProvider)(
                buildShareText(
                  title: args.title,
                  url: url,
                  style: args.style,
                  convertedText: result.convertedText,
                ),
                subject: args.title,
              ),
              child: CustomPaint(
                size: const Size(18, 18),
                painter: ShareIconPainter(AppColors.ink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OutlinedSquare extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _OutlinedSquare({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEAE4), width: 1.4),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
