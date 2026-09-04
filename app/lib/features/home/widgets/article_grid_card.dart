import 'package:flutter/material.dart';
import '../article.dart';
import '../../../core/theme/app_theme.dart';
import 'thirty_sec_badge.dart';

class ArticleGridCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleGridCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.thumbnailUrl != null)
              AspectRatio(
                aspectRatio: 3 / 2,
                child: Image.network(
                  article.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 24, color: Color(0xFF8E8E93)),
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 3 / 2,
                child: Container(color: const Color(0xFFEEEEEE)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (article.hasCardSummary) const ThirtySecBadge(),
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
