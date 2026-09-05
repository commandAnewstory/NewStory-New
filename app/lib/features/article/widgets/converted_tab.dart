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
            child: Text(
              result.convertedText,
              style: TextStyle(
                fontSize: 18,
                height: 1.7,
                color: _textColor,
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
                    Text('용어 보기'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
