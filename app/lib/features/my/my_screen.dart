import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'my_provider.dart';

const _menuItems = ['계정 정보', '알림 설정', '언어', '문의하기', '이용약관'];

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    final notifier = ref.read(myProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.profile == null
                ? _buildError(notifier)
                : _buildContent(context, state.profile!, notifier),
      ),
    );
  }

  Widget _buildError(MyNotifier notifier) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('정보를 불러오지 못했습니다'),
          const SizedBox(height: 12),
          TextButton(
              onPressed: notifier.fetchProfile, child: const Text('다시 시도')),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, UserProfile profile, MyNotifier notifier) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 100 + MediaQuery.of(context).padding.bottom),
      children: [
        // Header
        Text('MY', style: AppTextStyles.display(21)),
        const SizedBox(height: 20),
        // Profile card
        _ProfileCard(profile: profile),
        const SizedBox(height: 20),
        // Widget promo card
        _WidgetPromoCard(enabled: profile.widgetEnabled, onToggle: notifier.setWidgetEnabled),
        const SizedBox(height: 20),
        // Menu list
        _MenuList(onLogout: () => _confirmLogout(context, notifier)),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, MyNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('로그아웃',
                  style: TextStyle(color: Color(0xFFE0523F)))),
        ],
      ),
    );
    if (confirmed == true) await notifier.logout();
  }
}

// ──────────────────────── Sub-widgets ────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = profile.nickname.isNotEmpty
        ? profile.nickname[0]
        : profile.email.isNotEmpty
            ? profile.email[0].toUpperCase()
            : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEAE4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8ECFC),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(profile.email,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9A9CA3))),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(16, 16),
            painter: _ChevronPainter(const Color(0xFF9CA0A8)),
          ),
        ],
      ),
    );
  }
}

class _WidgetPromoCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _WidgetPromoCard({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: enabled ? AppColors.primary : const Color(0xFFECEAE4),
            width: enabled ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GridIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Text('오늘의 카드요약 위젯',
                    style: AppTextStyles.display(15)),
              ),
              GestureDetector(
                onTap: () => onToggle(!enabled),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.primary
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: enabled
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '홈 화면에서 앱을 열지 않고도 오늘의 카드요약 3개를 바로 볼 수 있어요',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF9A9CA3), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  final VoidCallback onLogout;

  const _MenuList({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEAE4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ..._menuItems.map((label) => _MenuItem(label: label)),
          _MenuItem(
            label: '로그아웃',
            textColor: const Color(0xFFE0523F),
            onTap: onLogout,
            showChevron: false,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final Color textColor;
  final VoidCallback? onTap;
  final bool showChevron;

  const _MenuItem({
    required this.label,
    this.textColor = const Color(0xFF33353B),
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF2F0EA))),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 13, color: textColor))),
            if (showChevron)
              CustomPaint(
                size: const Size(15, 15),
                painter: _ChevronPainter(const Color(0xFFD8D4CC)),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _GridIconPainter(AppColors.primary),
    );
  }
}

class _GridIconPainter extends CustomPainter {
  final Color color;
  const _GridIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 / s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // 2x2 grid of rounded squares
    for (final rx in [3.0, 13.0]) {
      for (final ry in [3.0, 13.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(rx, ry, 8, 8), const Radius.circular(2)),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GridIconPainter old) => old.color != color;
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  const _ChevronPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    canvas.drawPath(
      Path()
        ..moveTo(9, 6)
        ..lineTo(15, 12)
        ..lineTo(9, 18),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 / s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
