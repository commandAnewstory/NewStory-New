import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _styles = [
  ('original', '원문'),
  ('fairy_tale', '동화체'),
  ('novel', '소설체'),
  ('card', '카드요약'),
];

Color _activeColor(String value) {
  return switch (value) {
    'card' => const Color(0xFF14B8A6),
    _ => AppColors.primary,
  };
}

class StyleSegment extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const StyleSegment({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _styles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (value, label) = _styles[index];
          final isSelected = value == selected;
          final activeC = _activeColor(value);
          return GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? activeC : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? activeC : const Color(0xFFECEAE4),
                  width: 1.3,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: isSelected ? 'DoHyeon' : null,
                  fontSize: isSelected ? 13 : 12,
                  color: isSelected ? Colors.white : const Color(0xFF9A9CA3),
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
