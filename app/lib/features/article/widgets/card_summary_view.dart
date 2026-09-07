import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../article_detail_provider.dart';

class CardSummaryView extends StatelessWidget {
  final ConvertResult result;

  const CardSummaryView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final lines = result.convertedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.replaceFirst(RegExp(r'^[•·\-\d\.]+\s*'), ''))
        .where((l) => l.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      child: Column(
        children: lines.asMap().entries.map((entry) {
          final i = entry.key;
          final text = entry.value;
          return _CardPoint(index: i + 1, text: text);
        }).toList(),
      ),
    );
  }
}

class _CardPoint extends StatelessWidget {
  final int index;
  final String text;

  const _CardPoint({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF2F0EA))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.cardText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
