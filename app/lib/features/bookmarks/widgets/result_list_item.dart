import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _styleLabels = {
  'fairy_tale': '동화체',
  'novel': '소설체',
  'card': '카드요약',
};

const _styleBg = {
  'fairy_tale': AppColors.fairyTaleBg,
  'novel': AppColors.novelBg,
  'card': AppColors.cardBg,
};

const _styleText = {
  'fairy_tale': AppColors.fairyTaleText,
  'novel': AppColors.novelText,
  'card': AppColors.cardText,
};

class ResultListItem extends StatelessWidget {
  final String title;
  final String style;
  final String dateLabel;
  final VoidCallback onDelete;

  const ResultListItem({
    super.key,
    required this.title,
    required this.style,
    required this.dateLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _styleBg[style] ?? AppColors.background;
    final textColor = _styleText[style] ?? AppColors.ink;
    final label = _styleLabels[style] ?? style;

    return Dismissible(
      key: ValueKey(title + dateLabel),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFF3B30),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Color(0xFF8E8E93)),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
