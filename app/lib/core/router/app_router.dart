import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../../features/home/home_screen.dart';
import '../../features/convert/convert_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/my/my_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/article/article_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/signup';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'article/:id',
                  builder: (_, state) => ArticleDetailScreen(
                    articleId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/convert',
              builder: (_, _) => const ConvertScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bookmarks',
              builder: (_, _) => const BookmarksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/my',
              builder: (_, _) => const MyScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, _) => const SignupScreen(),
      ),
    ],
  );
});

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _AppNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ──────────────────────── Custom Nav Bar ────────────────────────

class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppNavBar({required this.currentIndex, required this.onTap});

  static const _active = Color(0xFF3654F4);
  static const _inactive = Color(0xFF9CA0A8);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 66 + bottom,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECEAE4))),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(label: '홈', active: currentIndex == 0, onTap: () => onTap(0),
              painter: _HomePainter(currentIndex == 0 ? _active : _inactive)),
          _NavItem(label: '변환', active: currentIndex == 1, onTap: () => onTap(1),
              painter: _ConvertPainter(currentIndex == 1 ? _active : _inactive)),
          _NavItem(label: '보관함', active: currentIndex == 2, onTap: () => onTap(2),
              painter: _BookmarkPainter(currentIndex == 2 ? _active : _inactive)),
          _NavItem(label: 'MY', active: currentIndex == 3, onTap: () => onTap(3),
              painter: _PersonPainter(currentIndex == 3 ? _active : _inactive)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final CustomPainter painter;

  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(size: const Size(21, 21), painter: painter),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? const Color(0xFF3654F4) : const Color(0xFF9CA0A8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Icon Painters ────────────────────────

abstract class _StrokePainter extends CustomPainter {
  final Color color;
  const _StrokePainter(this.color);

  @override
  bool shouldRepaint(covariant _StrokePainter old) => old.color != color;

  Paint _p(double scale, {double sw = 1.75}) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = sw / scale
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

class _HomePainter extends _StrokePainter {
  const _HomePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s);
    canvas.drawPath(Path()..moveTo(4, 11.5)..lineTo(12, 4)..lineTo(20, 11.5), p);
    canvas.drawPath(Path()..moveTo(6, 10)..lineTo(6, 19)..lineTo(18, 19)..lineTo(18, 10), p);
  }
}

class _ConvertPainter extends _StrokePainter {
  const _ConvertPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s);
    canvas.drawPath(Path()
      ..moveTo(7, 7)..lineTo(18, 7)
      ..moveTo(14.5, 3.5)..lineTo(18, 7)..lineTo(14.5, 10.5), p);
    canvas.drawPath(Path()
      ..moveTo(17, 17)..lineTo(6, 17)
      ..moveTo(9.5, 13.5)..lineTo(6, 17)..lineTo(9.5, 20.5), p);
  }
}

class _BookmarkPainter extends _StrokePainter {
  const _BookmarkPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    canvas.drawPath(
      Path()..moveTo(6, 4)..lineTo(18, 4)..lineTo(18, 20)..lineTo(12, 16)..lineTo(6, 20)..close(),
      _p(s, sw: 1.75),
    );
  }
}

class _PersonPainter extends _StrokePainter {
  const _PersonPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s);
    canvas.drawPath(Path()..addOval(Rect.fromCircle(center: const Offset(12, 8), radius: 3.2)), p);
    canvas.drawPath(Path()
      ..moveTo(5, 20)
      ..cubicTo(6.2, 16, 9, 14, 12, 14)
      ..cubicTo(15, 14, 17.8, 16, 19, 20), p);
  }
}

// ──────────────────────── Shared Icon Painters (used in other screens) ────────────────────────

class SearchIconPainter extends _StrokePainter {
  const SearchIconPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s, sw: 1.7);
    canvas.drawPath(Path()..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 7)), p);
    canvas.drawPath(Path()..moveTo(16.7, 16.7)..lineTo(21, 21), p);
  }
}

class BellIconPainter extends _StrokePainter {
  const BellIconPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s, sw: 1.7);
    // bell body approximation
    canvas.drawPath(Path()
      ..moveTo(18, 8)
      ..arcToPoint(const Offset(6, 8), radius: const Radius.circular(6), clockwise: false)
      ..cubicTo(6, 12, 3, 14, 3, 17)
      ..lineTo(21, 17)
      ..cubicTo(21, 14, 18, 12, 18, 8), p);
    canvas.drawPath(Path()
      ..moveTo(13.7, 21)
      ..arcToPoint(const Offset(10.3, 21), radius: const Radius.circular(2), clockwise: false), p);
  }
}

class BackChevronPainter extends _StrokePainter {
  const BackChevronPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    canvas.drawPath(
      Path()..moveTo(15, 5)..lineTo(8, 12)..lineTo(15, 19),
      _p(s, sw: 1.8),
    );
  }
}

class ShareIconPainter extends _StrokePainter {
  const ShareIconPainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = _p(s, sw: 1.7);
    canvas.drawPath(Path()..addOval(Rect.fromCircle(center: const Offset(18, 5), radius: 2.4)), p);
    canvas.drawPath(Path()..addOval(Rect.fromCircle(center: const Offset(6, 12), radius: 2.4)), p);
    canvas.drawPath(Path()..addOval(Rect.fromCircle(center: const Offset(18, 19), radius: 2.4)), p);
    canvas.drawPath(Path()
      ..moveTo(8.2, 10.8)..lineTo(15.8, 6.4)
      ..moveTo(8.2, 13.2)..lineTo(15.8, 17.6), p);
  }
}

class BookmarkSavePainter extends _StrokePainter {
  const BookmarkSavePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    canvas.drawPath(
      Path()..moveTo(6, 4)..lineTo(18, 4)..lineTo(18, 20)..lineTo(12, 16)..lineTo(6, 20)..close(),
      _p(s, sw: 1.8),
    );
  }
}

// suppress unused import warning
final _mathUnused = math.pi;
