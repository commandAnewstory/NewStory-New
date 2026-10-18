import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../home/widgets/category_chip_bar.dart' show categories;
import 'my_provider.dart';

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
        const SizedBox(height: 12),
        _InterestCard(
          selected: profile.interestCategories,
          onToggle: (category) async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await notifier.toggleInterest(category);
            if (!ok) {
              messenger.showSnackBar(const SnackBar(
                content: Text('관심 카테고리를 저장하지 못했어요. 다시 시도해 주세요.'),
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
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
                child: Text('관심 뉴스 위젯',
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
            '관심 카테고리의 오늘 인기 뉴스 3개를 홈 화면에서 바로 보고, 누르면 카드요약으로 읽어요',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF9A9CA3), height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 관심 카테고리 — 위젯 "관심 뉴스"에 쓰인다. 하나도 안 고르면 전체.
class _InterestCard extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _InterestCard({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final options = categories.where((c) => c != '전체').toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEAE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('관심 카테고리', style: AppTextStyles.display(15)),
          const SizedBox(height: 4),
          Text(
            selected.isEmpty ? '안 고르면 전체 카테고리에서 골라요' : '${selected.length}개 선택',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9A9CA3)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in options)
                _InterestChip(
                  label: c,
                  selected: selected.contains(c),
                  onTap: () => onToggle(c),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('interest-$label'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFECEAE4), width: 1.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : const Color(0xFF6B6E76),
          ),
        ),
      ),
    );
  }
}

/// 2026-10-12: 동작 없던 메뉴 5개(계정 정보/알림 설정/언어/문의하기/이용약관) 제거, 로그아웃만 남김
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
      child: GestureDetector(
        onTap: onLogout,
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text('로그아웃',
              style: TextStyle(fontSize: 13, color: Color(0xFFE0523F))),
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
