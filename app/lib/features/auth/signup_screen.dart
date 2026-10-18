import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'signup_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit(SignupNotifier notifier) async {
    if (_pwCtrl.text != _pw2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    await notifier.signup(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      nickname: _nicknameCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);
    final notifier = ref.read(signupProvider.notifier);

    ref.listen(signupProvider, (_, next) {
      if (next.status == SignupStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), behavior: SnackBarBehavior.floating),
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
              Text('계정 만들기', style: AppTextStyles.display(26).copyWith(height: 1.45)),
              const SizedBox(height: 40),
              _Field(controller: _nicknameCtrl, hint: '닉네임'),
              const SizedBox(height: 10),
              _Field(
                  controller: _emailCtrl,
                  hint: '이메일',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _Field(controller: _pwCtrl, hint: '비밀번호 (최소 8자)', obscure: true),
              const SizedBox(height: 10),
              _Field(controller: _pw2Ctrl, hint: '비밀번호 확인', obscure: true),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: state.isLoading ? null : () => _submit(notifier),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: state.isLoading
                        ? AppColors.primary.withAlpha(160)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('가입하기',
                          style: AppTextStyles.display(15).copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('이미 계정이 있으신가요?',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9A9CA3))),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('로그인',
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
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;

  const _Field({
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
