import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

const _options = [
  (
    value: 'fairy_tale',
    label: '동화체',
    desc: '쉽고 친근하게, 아이도 이해할 수 있게',
    bg: AppColors.fairyTaleBg,
    iconColor: AppColors.fairyTaleText,
  ),
  (
    value: 'novel',
    label: '소설체',
    desc: '이야기처럼 몰입감 있게',
    bg: AppColors.novelBg,
    iconColor: AppColors.novelText,
  ),
  (
    value: 'card',
    label: '카드요약',
    desc: '핵심만 30초 컷으로',
    bg: AppColors.cardBg,
    iconColor: AppColors.cardText,
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
                  child: CustomPaint(
                    painter: _StyleIconPainter(opt.value, opt.iconColor),
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

class _StyleIconPainter extends CustomPainter {
  final String style;
  final Color color;

  _StyleIconPainter(this.style, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.038
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 24;
    canvas.translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2);
    canvas.scale(s, s);

    switch (style) {
      case 'fairy_tale':
        // Book icon
        canvas.drawPath(
          Path()
            ..moveTo(4, 6)
            ..cubicTo(7, 4, 10, 5, 12, 6)
            ..lineTo(12, 19)
            ..cubicTo(10, 18, 7, 17, 4, 19)
            ..close(),
          paint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20, 6)
            ..cubicTo(17, 4, 14, 5, 12, 6)
            ..lineTo(12, 19)
            ..cubicTo(14, 18, 17, 17, 20, 19)
            ..close(),
          paint,
        );
      case 'novel':
        // Pen/quill icon
        canvas.drawPath(
          Path()
            ..moveTo(4, 20)
            ..lineTo(18, 6)
            ..moveTo(14, 4)
            ..lineTo(18, 4)
            ..lineTo(20, 6)
            ..lineTo(18, 8)
            ..lineTo(14, 4)
            ..close(),
          paint,
        );
      case 'card':
        // Cards icon
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(5, 5, 12, 14), const Radius.circular(2)),
            paint);
        canvas.drawPath(
          Path()
            ..moveTo(9, 3)
            ..lineTo(21, 3)
            ..lineTo(21, 17),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_StyleIconPainter old) => old.color != color || old.style != style;
}
