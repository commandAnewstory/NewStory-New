import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../article/widgets/converted_tab.dart';
import '../article/widgets/card_summary_view.dart';
import '../article/widgets/glossary_sheet.dart';
import 'convert_provider.dart';
import 'widgets/url_input_field.dart';
import 'widgets/style_picker.dart';

class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertProvider);
    final notifier = ref.read(convertProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('직접 변환',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          UrlInputField(
            value: state.url,
            onChanged: notifier.setUrl,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('스타일 선택',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink.withAlpha(180))),
          ),
          const SizedBox(height: 8),
          StylePicker(
            selected: state.selectedStyle,
            onSelected: notifier.setStyle,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: state.canConvert ? notifier.convert : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('변환하기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildResult(context, state)),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, ConvertState state) {
    if (state.isConverting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF636366))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ProviderScope.containerOf(context).read(convertProvider.notifier).retry(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final result = state.result;
    if (result == null) {
      return Center(
        child: Text(
          'URL을 입력하고 스타일을 선택하면\n변환 결과가 여기에 표시됩니다',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: AppColors.ink.withAlpha(120), height: 1.6),
        ),
      );
    }

    if (state.selectedStyle == 'card') {
      return CardSummaryView(result: result);
    }

    return ConvertedTab(
      style: state.selectedStyle!,
      result: result,
      onShowGlossary: result.glossary.isNotEmpty
          ? () => GlossarySheet.show(context, result.glossary)
          : null,
    );
  }
}
