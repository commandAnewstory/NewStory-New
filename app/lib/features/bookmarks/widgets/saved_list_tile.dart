import 'package:flutter/material.dart';

import '../../home/widgets/category_colors.dart';
import '../saved_filter.dart';

const savedStyleLabels = {'fairy_tale': '동화체', 'novel': '소설체', 'card': '카드요약'};
const savedStyleBg = {
  'fairy_tale': Color(0xFFFDECC8),
  'novel': Color(0xFFE6DEFA),
  'card': Color(0xFFD7F3EE),
};
const savedStyleText = {
  'fairy_tale': Color(0xFF8A5A0F),
  'novel': Color(0xFF5A3A9E),
  'card': Color(0xFF0B6E64),
};

/// 홈 기사 목록과 같은 모양의 보관함·히스토리 한 줄. 누르면 열기, 길게 누르면 삭제 확인.
class SavedListTile extends StatelessWidget {
  final SavedEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SavedListTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  static String timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final category = entry.category;
    final cat = category == null || category.isEmpty ? null : CategoryColors.of(category);
    final time = timeAgo(entry.time);

    return InkWell(
      key: Key('saved-tile-${entry.resultId}'),
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (cat != null) ...[
                  _Badge(label: category!, bg: cat.bg, fg: cat.text),
                  const SizedBox(width: 6),
                ],
                _Badge(
                  label: savedStyleLabels[entry.style] ?? entry.style,
                  bg: savedStyleBg[entry.style] ?? const Color(0xFFE8ECFC),
                  fg: savedStyleText[entry.style] ?? const Color(0xFF3654F4),
                ),
                const Spacer(),
                if (time.isNotEmpty)
                  Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBC0))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17181C),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// 변환종류 필터 칩 줄 (전체/동화체/소설체/카드요약)
class SavedStyleFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const SavedStyleFilterBar({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: savedStyleOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (value, label) = savedStyleOptions[i];
          final isSelected = value == selected;
          final fg = savedStyleText[value] ?? const Color(0xFF17181C);
          final bg = savedStyleBg[value] ?? const Color(0xFFECEAE4);
          return GestureDetector(
            key: Key('style-filter-$value'),
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? bg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? fg : const Color(0xFFECEAE4), width: 1.2),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? fg : const Color(0xFF9A9CA3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
