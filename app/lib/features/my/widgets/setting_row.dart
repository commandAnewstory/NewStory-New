import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const SettingRow({super.key, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 14, color: AppColors.ink)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}
