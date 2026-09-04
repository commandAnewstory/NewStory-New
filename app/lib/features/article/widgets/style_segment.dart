import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _styles = [
  ('fairy_tale', '동화체'),
  ('novel', '소설체'),
  ('card', '카드요약'),
];

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: _styles.map((entry) {
          final (value, label) = entry;
          final isSelected = value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.ink : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
