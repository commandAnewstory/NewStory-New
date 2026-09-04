import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ThirtySecBadge extends StatelessWidget {
  const ThirtySecBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '30초 컷',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.cardText,
        ),
      ),
    );
  }
}
