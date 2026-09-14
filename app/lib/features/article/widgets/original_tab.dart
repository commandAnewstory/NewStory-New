import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OriginalTab extends StatelessWidget {
  final String text;

  const OriginalTab({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < paragraphs.length; i++) ...[
            Text(
              paragraphs[i],
              style: const TextStyle(
                fontSize: 16,
                height: 1.75,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
            ),
            if (i < paragraphs.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
