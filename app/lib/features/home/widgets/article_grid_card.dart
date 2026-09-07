import 'package:flutter/material.dart';
import '../article.dart';
import 'category_colors.dart';

class ArticleGridCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleGridCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColors = CategoryColors.of(article.category);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          AspectRatio(
            aspectRatio: 1.38,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7E4DE)),
                color: const Color(0xFFF0F0EC),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const _SmallStripedBg(),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColors.bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF17181C),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SmallStripedBg extends StatelessWidget {
  const _SmallStripedBg();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _SmallStripePainter()));
  }
}

class _SmallStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFFF0F0EC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);
    final p2 = Paint()
      ..color = const Color(0xFFF7F7F4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    const gap = 16.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p2);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
