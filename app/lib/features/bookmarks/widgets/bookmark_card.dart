import 'package:flutter/material.dart';

const _styleLabels = {
  'fairy_tale': '동화체',
  'novel': '소설체',
  'card': '카드요약',
};
const _styleBg = {
  'fairy_tale': Color(0xFFFDECC8),
  'novel': Color(0xFFE6DEFA),
  'card': Color(0xFFD7F3EE),
};
const _styleText = {
  'fairy_tale': Color(0xFF8A5A0F),
  'novel': Color(0xFF5A3A9E),
  'card': Color(0xFF0B6E64),
};

class BookmarkCard extends StatelessWidget {
  final String title;
  final String style;
  final String dateLabel;
  final VoidCallback onDelete;

  const BookmarkCard({
    super.key,
    required this.title,
    required this.style,
    required this.dateLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _styleBg[style] ?? const Color(0xFFE8ECFC);
    final textColor = _styleText[style] ?? const Color(0xFF3654F4);
    final label = _styleLabels[style] ?? style;

    return GestureDetector(
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('삭제'),
            content: const Text('이 항목을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제',
                      style: TextStyle(color: Color(0xFFFF3B30)))),
            ],
          ),
        );
        if (confirmed == true) onDelete();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEAE4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder (88px-ish)
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF0F0EC),
                child: Stack(
                  children: [
                    const _StripedBg(),
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF17181C),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA0A8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripedBg extends StatelessWidget {
  const _StripedBg();
  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: CustomPaint(painter: _StripePainter()));
}

class _StripePainter extends CustomPainter {
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
