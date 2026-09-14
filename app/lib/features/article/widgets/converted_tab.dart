import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../article_detail_provider.dart';

class ConvertedTab extends StatelessWidget {
  final String style;
  final ConvertResult result;
  final VoidCallback? onShowGlossary;

  const ConvertedTab({
    super.key,
    required this.style,
    required this.result,
    this.onShowGlossary,
  });

  Color get _bgColor => switch (style) {
        'fairy_tale' => AppColors.fairyTaleBg,
        'novel' => AppColors.novelBg,
        _ => AppColors.background,
      };

  Color get _textColor => switch (style) {
        'fairy_tale' => AppColors.fairyTaleText,
        'novel' => AppColors.novelText,
        _ => AppColors.ink,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  height: 1.7,
                  color: _textColor,
                  fontFamily: null,
                ),
                children: _buildSpans(context),
              ),
            ),
          ),
          if (result.glossary.isNotEmpty && onShowGlossary != null)
            Positioned(
              bottom: 24,
              right: 20,
              child: FilledButton.tonal(
                onPressed: onShowGlossary,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('용어 전체 보기'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    final text = result.convertedText;
    final glossary = result.glossary;

    if (glossary.isEmpty) {
      return [TextSpan(text: text)];
    }

    final sorted = List<GlossaryItem>.from(glossary)
      ..sort((a, b) => b.term.length.compareTo(a.term.length));

    final pattern = RegExp(
      sorted.map((e) => RegExp.escape(e.term)).join('|'),
    );

    final spans = <InlineSpan>[];
    int current = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > current) {
        spans.add(TextSpan(text: text.substring(current, match.start)));
      }
      final term = match.group(0)!;
      final item = sorted.firstWhere((e) => e.term == term);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _showTermPopup(context, item);
      spans.add(
        TextSpan(
          text: term,
          style: const TextStyle(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.primary,
          ),
          recognizer: recognizer,
        ),
      );
      current = match.end;
    }

    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current)));
    }

    return spans;
  }

  void _showTermPopup(BuildContext context, GlossaryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.term,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.definition,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
