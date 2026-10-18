import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _options = [
  (
    value: 'fairy_tale',
    label: '동화체',
    desc: '쉽고 친근하게, 아이도 이해할 수 있게',
    bg: AppColors.fairyTaleBg,
    icon: 'assets/icons/style_fairy_tale.png',
  ),
  (
    value: 'novel',
    label: '소설체',
    desc: '이야기처럼 몰입감 있게',
    bg: AppColors.novelBg,
    icon: 'assets/icons/style_novel.png',
  ),
  (
    value: 'card',
    label: '카드요약',
    desc: '핵심만 30초 컷으로',
    bg: AppColors.cardBg,
    icon: 'assets/icons/style_card.png',
  ),
];

class StylePicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const StylePicker({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _options.map((opt) {
        final isSelected = opt.value == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFECEAE4),
                width: isSelected ? 2 : 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: opt.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    opt.icon,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.label,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(opt.desc,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9A9CA3))),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFD8D4CC),
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
