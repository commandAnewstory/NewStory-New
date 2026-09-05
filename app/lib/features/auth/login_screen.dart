import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'login_provider.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    ref.listen(loginProvider, (prev, next) {
      if (next.status == LoginStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Text(
                'NewStory',
                style: AppTextStyles.display(36),
              ),
              const SizedBox(height: 12),
              const Text(
                '뉴스를 거부감 없이, 재밌고 가볍게',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.ink,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              if (state.isLoading)
                const CircularProgressIndicator()
              else ...[
                SocialLoginButton(
                  label: '카카오로 시작하기',
                  icon: Image.asset('assets/icons/kakao.png',
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.chat_bubble, color: Colors.black54, size: 20)),
                  backgroundColor: const Color(0xFFFEE500),
                  textColor: const Color(0xFF191919),
                  onTap: notifier.loginWithKakao,
                ),
                const SizedBox(height: 12),
                SocialLoginButton(
                  label: '구글로 시작하기',
                  icon: _GoogleIcon(),
                  backgroundColor: Colors.white,
                  textColor: AppColors.ink,
                  borderColor: const Color(0xFFD1D1D6),
                  onTap: notifier.loginWithGoogle,
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GooglePainter(), size: const Size(24, 24));
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    // G 로고 근사: 4색 원호
    const sweepDeg = 3.14159265 / 2;
    const colors = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        sweepDeg * i - 3.14159265 / 4,
        sweepDeg,
        true,
        paint,
      );
    }
    // 중앙 구멍
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
