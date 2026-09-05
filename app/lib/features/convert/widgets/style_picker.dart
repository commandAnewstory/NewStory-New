import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _styleOptions = [
  (value: 'fairy_tale', label: '동화체', desc: '쉽고 재밌게', bg: AppColors.fairyTaleBg, text: AppColors.fairyTaleText),
  (value: 'novel', label: '소설체', desc: '몰입감 있게', bg: AppColors.novelBg, text: AppColors.novelText),
  (value: 'card', label: '카드요약', desc: '30초 만에', bg: AppColors.cardBg, text: AppColors.cardText),
];

class StylePicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const StylePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _styleOptions.map((opt) {
          final isSelected = opt.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? opt.bg : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? opt.text.withAlpha(100) : const Color(0xFFE5E5EA),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? opt.text : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? opt.text : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
