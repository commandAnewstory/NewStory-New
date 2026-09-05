import 'package:flutter/material.dart';
import '../article.dart';
import '../../../core/theme/app_theme.dart';
import 'thirty_sec_badge.dart';

class HeroCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const HeroCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryTag(article.category),
                  if (article.source != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      article.source!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8E8E93)),
                    ),
                  ],
                  const Spacer(),
                  const ThirtySecBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  article.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF636366),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String category;
  const _CategoryTag(this.category);

  @override
  Widget build(BuildContext context) {
    return Text(
      category,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    );
  }
}
