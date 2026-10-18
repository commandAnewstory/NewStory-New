import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'login_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final notifier = ref.read(loginProvider.notifier);

    ref.listen(loginProvider, (_, next) {
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo + tagline
              _buildLogo(),
              const SizedBox(height: 40),
              // Social buttons
              _KakaoButton(onTap: state.isLoading ? null : notifier.loginWithKakao),
              const SizedBox(height: 10),
              _GoogleButton(onTap: state.isLoading ? null : notifier.loginWithGoogle),
              const SizedBox(height: 22),
              // OR divider
              _OrDivider(),
              const SizedBox(height: 22),
              // Email + PW fields
              _InputField(controller: _emailCtrl, hint: '이메일', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _InputField(controller: _pwCtrl, hint: '비밀번호', obscure: true),
              const SizedBox(height: 18),
              // Login button
              _LoginButton(
                loading: state.isLoading,
                onTap: () => notifier.loginWithEmail(_emailCtrl.text.trim(), _pwCtrl.text),
              ),
              const SizedBox(height: 60),
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('아직 계정이 없으신가요?',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9A9CA3))),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: const Text('회원가입',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text('NS', style: AppTextStyles.display(17).copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 20),
        Text(
          '뉴스를 가볍게,\n재밌게 볼 시간',
          style: AppTextStyles.display(26).copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _KakaoButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _KakaoButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kakao bubble icon
            CustomPaint(size: const Size(18, 18), painter: _KakaoPainter()),
            const SizedBox(width: 10),
            const Text('카카오로 시작하기',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3A1D1D))),
          ],
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E4DE), width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(size: const Size(17, 17), painter: _GooglePainter()),
            const SizedBox(width: 10),
            const Text('Google로 시작하기',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFECEAE4))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('또는 이메일로 계속하기',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA0A8))),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFECEAE4))),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECEAE4), width: 1.4),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA0A8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: loading ? const Color(0xFF888888) : AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('로그인',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}

// ──────────────────────── Icon Painters ────────────────────────

class _KakaoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A1D1D)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..cubicTo(size.width * 0.23, 0, 0, size.width * 0.27, 0, size.width * 0.46)
      ..cubicTo(0, size.width * 0.58, 0.08 * size.width, size.width * 0.69,
          0.2 * size.width, size.width * 0.76)
      ..lineTo(size.width * 0.12, size.width * 1.0)
      ..cubicTo(size.width * 0.12, size.width * 1.0, size.width * 0.38, size.width * 0.83,
          size.width * 0.42, size.width * 0.79)
      ..cubicTo(size.width * 0.45, size.width * 0.79, size.width * 0.47, size.width * 0.79,
          size.width * 0.5, size.width * 0.79)
      ..cubicTo(size.width * 0.77, size.width * 0.79, size.width, size.width * 0.63,
          size.width, size.width * 0.46)
      ..cubicTo(size.width, size.width * 0.27, size.width * 0.77, 0, size.width * 0.5, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;
    const colors = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    const sweep = 3.14159265 / 2;
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        sweep * i - 3.14159265 / 4,
        sweep,
        true,
        paint,
      );
    }
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
