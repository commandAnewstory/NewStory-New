import 'package:flutter/material.dart';
import '../article.dart';
import 'category_colors.dart';

class HeroCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const HeroCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColors = CategoryColors.of(article.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        height: 224,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7E4DE)),
          color: const Color(0xFFE8ECFC),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Striped placeholder background
            const _StripedBg(),
            // Category badge
            Positioned(
              top: 12,
              left: 12,
              child: _CategoryBadge(
                label: article.category,
                bg: catColors.bg,
                textColor: catColors.text,
              ),
            ),
            // Gradient + title + style badges
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xC7111219), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _StyleBadgeRow(),
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

class _StyleBadgeRow extends StatelessWidget {
  const _StyleBadgeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StyleBadge(label: '동화체', bg: Color(0xFFFDECC8), textColor: Color(0xFF8A5A0F)),
        SizedBox(width: 6),
        _StyleBadge(label: '소설체', bg: Color(0xFFE6DEFA), textColor: Color(0xFF5A3A9E)),
        SizedBox(width: 6),
        _StyleBadge(label: '카드요약', bg: Color(0xFFD7F3EE), textColor: Color(0xFF0B6E64)),
      ],
    );
  }
}

class _StyleBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _StyleBadge({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _CategoryBadge({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _StripedBg extends StatelessWidget {
  const _StripedBg();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _StripePainter()),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE8ECFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.color = const Color(0xFFF1F3FD);
    const gap = 20.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint..strokeWidth = 10);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
