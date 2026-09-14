import 'package:flutter/material.dart';
import '../article.dart';
import 'category_colors.dart';

class ArticleListTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleListTile({
    super.key,
    required this.article,
    required this.onTap,
  });

  String _timeAgo(String publishedAt) {
    try {
      final dt = DateTime.parse(publishedAt);
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

  @override
  Widget build(BuildContext context) {
    final catColors = CategoryColors.of(article.category);
    final timeAgo = _timeAgo(article.publishedAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColors.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: catColors.text,
                    ),
                  ),
                ),
                if (article.source != null && article.source!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    article.source!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9CA3),
                    ),
                  ),
                ],
                const Spacer(),
                if (timeAgo.isNotEmpty)
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBBBBC0),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17181C),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (article.description != null &&
                article.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                article.description!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A9CA3),
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
