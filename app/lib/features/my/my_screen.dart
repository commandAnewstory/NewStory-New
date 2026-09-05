import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'my_provider.dart';
import 'widgets/setting_row.dart';

const _levelLabels = {
  'LOW': '쉬움',
  'MEDIUM': '보통',
  'HIGH': '어려움',
};

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    final notifier = ref.read(myProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.profile == null
              ? _buildError(notifier)
              : _buildContent(context, state.profile!, notifier),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _SectionHeader('프로필'),
        SettingRow(
          label: '이메일',
          trailing: Text(profile.email,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        ),
        const SizedBox(height: 4),
        SettingRow(
          label: '닉네임',
          trailing: Text(profile.nickname,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        ),
        const SizedBox(height: 24),
        _SectionHeader('설정'),
        SettingRow(
          label: '용어 난이도',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD1D1D6)),
            ),
            child: Text(
              _levelLabels[profile.lastGlossaryLevel] ?? profile.lastGlossaryLevel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF636366)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SettingRow(
          label: '홈 위젯',
          trailing: Switch.adaptive(
            value: profile.widgetEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: notifier.setWidgetEnabled,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton(
            onPressed: () => _confirmLogout(context, notifier),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
              side: const BorderSide(color: Color(0xFFFF3B30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('로그아웃',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
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
                  style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirmed == true) await notifier.logout();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
