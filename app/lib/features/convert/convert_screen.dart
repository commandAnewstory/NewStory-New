import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../article/widgets/converted_tab.dart';
import '../article/widgets/card_summary_view.dart';
import '../article/widgets/glossary_sheet.dart';
import 'convert_provider.dart';
import 'widgets/url_input_field.dart';
import 'widgets/style_picker.dart';

const _supportedSources = ['네이버뉴스', '조선일보', '중앙일보', '동아일보', 'SBS', 'MBC'];

class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertProvider);
    final notifier = ref.read(convertProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Inline header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('직접 변환', style: AppTextStyles.display(21)),
                  const SizedBox(height: 4),
                  const Text(
                    '뉴스 링크를 붙여넣으면 원하는 스타일로 바꿔드려요',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9A9CA3)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, 40 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // URL input
                    UrlInputField(value: state.url, onChanged: notifier.setUrl),
                    const SizedBox(height: 14),
                    // Supported sources
                    const Text('지원 언론사',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9A9CA3))),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _supportedSources.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFECEAE4), width: 1.2),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4A4D55),
                                  fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),
                    // Style picker
                    const Text('어떤 스타일로 볼까요',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(height: 12),
                    StylePicker(
                      selected: state.selectedStyle,
                      onSelected: notifier.setStyle,
                    ),
                    const SizedBox(height: 24),
                    // CTA button
                    GestureDetector(
                      onTap: state.canConvert && !state.isConverting
                          ? notifier.convert
                          : null,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: state.canConvert
                              ? AppColors.primary
                              : AppColors.primary.withAlpha(100),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: state.isConverting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('변환 시작하기',
                                style: AppTextStyles.display(15)
                                    .copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '유튜브·SNS·페이월 기사는 지원하지 않아요',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA0A8)),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(state.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFF636366), fontSize: 14)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ProviderScope.containerOf(context)
                                  .read(convertProvider.notifier)
                                  .retry(),
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (state.result != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFECEAE4)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: state.selectedStyle == 'card'
                            ? SizedBox(
                                height: 400,
                                child: CardSummaryView(result: state.result!),
                              )
                            : SizedBox(
                                height: 400,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: ConvertedTab(
                                    style: state.selectedStyle!,
                                    result: state.result!,
                                    onShowGlossary: state.result!.glossary.isNotEmpty
                                        ? () => GlossarySheet.show(
                                            context, state.result!.glossary)
                                        : null,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
