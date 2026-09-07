import 'package:flutter/material.dart';

class CategoryColors {
  final Color bg;
  final Color text;
  const CategoryColors({required this.bg, required this.text});

  static CategoryColors of(String category) {
    return switch (category) {
      '정치' => const CategoryColors(bg: Color(0xFFFDECC8), text: Color(0xFF8A5A0F)),
      '경제' => const CategoryColors(bg: Color(0xFFE8ECFC), text: Color(0xFF3654F4)),
      '사회' => const CategoryColors(bg: Color(0xFFF0F0F0), text: Color(0xFF5A5C63)),
      '국제' => const CategoryColors(bg: Color(0xFFFBE3D4), text: Color(0xFFB8501C)),
      '스포츠' => const CategoryColors(bg: Color(0xFFDCEBFB), text: Color(0xFF1D6FB8)),
      'IT' => const CategoryColors(bg: Color(0xFFE8ECFC), text: Color(0xFF3654F4)),
      '문화' || '생활·문화' => const CategoryColors(bg: Color(0xFFE6DEFA), text: Color(0xFF5A3A9E)),
      _ => const CategoryColors(bg: Color(0xFFE8ECFC), text: Color(0xFF3654F4)),
    };
  }
}
