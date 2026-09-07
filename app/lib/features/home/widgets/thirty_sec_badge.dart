import 'package:flutter/material.dart';

class ThirtySecBadge extends StatelessWidget {
  const ThirtySecBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '30초 컷',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
