import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/home/widgets/thirty_sec_badge.dart';
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
        .toList();

    return Container(
      color: AppColors.cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (result.readingTimeLabel != null)
                  Text(
                    result.readingTimeLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.cardText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                const ThirtySecBadge(),
              ],
            ),
            const SizedBox(height: 16),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 10),
                      child: Icon(Icons.circle, size: 7, color: AppColors.cardText),
                    ),
                    Expanded(
                      child: Text(
                        line.replaceFirst(RegExp(r'^[•·\-]\s*'), ''),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.cardText,
                        ),
                      ),
                    ),
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
