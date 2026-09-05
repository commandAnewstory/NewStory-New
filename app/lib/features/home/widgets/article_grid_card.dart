import 'package:flutter/material.dart';
import '../article.dart';
import '../../../core/theme/app_theme.dart';

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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.source != null) ...[
                const Spacer(),
                Text(
                  article.source!,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8E8E93)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
