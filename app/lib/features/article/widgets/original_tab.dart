import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OriginalTab extends StatelessWidget {
  final String text;

  const OriginalTab({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.7,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
