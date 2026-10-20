import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/article/article_detail_provider.dart';
import '../auth/auth_notifier.dart';
import '../theme/app_theme.dart';
import 'convert_jobs.dart';

const _styleLabels = {'fairy_tale': '동화체', 'novel': '소설체', 'card': '카드요약'};

// 동화체 팔레트의 노랑 계열
const _runningBg = Color(0xFFFDECC8);
const _runningFg = Color(0xFF8A5A0F);
const _ring = Color(0xFFE0A21B);
const _doneBg = Color(0xFFFFC83D);
const _failRed = Color(0xFFD94B4B);

/// MaterialApp.router의 builder용 — 앱 전체 위에 변환 플로팅 버튼을 얹는다
Widget withConvertJobsFab(GoRouter router, Widget? child) => Stack(
      fit: StackFit.expand,
      children: [
        child ?? const SizedBox.shrink(),
        ConvertJobsFab(router: router),
      ],
    );

/// 상세 화면 밖으로 나가도 변환 상태를 알려주는 플로팅 버튼.
/// 변환이 하나라도 걸려 있을 때만 생기고, 로그아웃 상태·로그인 화면에선 안 보인다.
/// 그 기사 상세 화면에선 그 기사 작업은 빼고 보여준다 (화면에 이미 로딩/결과가 보이니까).
class ConvertJobsFab extends ConsumerStatefulWidget {
  final GoRouter router;
  const ConvertJobsFab({super.key, required this.router});

  @override
  ConsumerState<ConvertJobsFab> createState() => _ConvertJobsFabState();
}

class _ConvertJobsFabState extends ConsumerState<ConvertJobsFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// 지금 보고 있는 기사 id (기사 상세 화면일 때)
  int? _currentArticleId(String location) {
    final m = RegExp(r'/article/(\d+)').firstMatch(location);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  @override
  Widget build(BuildContext context) {
    // 생성이 끝나는 순간 한 번 흔들기
    ref.listen<List<ConvertJob>>(convertJobsProvider, (prev, next) {
      final before = {
        for (final j in prev ?? const <ConvertJob>[]) '${j.articleId}/${j.style}': j.status
      };
      final finishedNow = next.any((j) =>
          j.status != ConvertJobStatus.running &&
          before['${j.articleId}/${j.style}'] == ConvertJobStatus.running);
      if (finishedNow && !MediaQuery.of(context).disableAnimations) _shake.forward(from: 0);
    });

    final loggedIn = ref.watch(authProvider).isLoggedIn;
    final jobs = ref.watch(convertJobsProvider);
    if (!loggedIn || jobs.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: widget.router.routerDelegate,
      builder: (context, _) {
        // push로 쌓인 화면까지 반영된 맨 위 화면 경로
        final location = widget.router.state.uri.path;
        if (location == '/login' || location == '/signup') return const SizedBox.shrink();
        final here = _currentArticleId(location);
        final visible = jobs.where((j) => j.articleId != here).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        final running = visible.where((j) => j.status == ConvertJobStatus.running).length;
        final failed = visible.where((j) => j.status == ConvertJobStatus.failed).length;
        final allDone = running == 0;
        final bottom = MediaQuery.of(context).viewPadding.bottom + 96;

        return Positioned(
          right: 16,
          bottom: bottom,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              final dx = math.sin(t * math.pi * 6) * 6 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            // 앱 Navigator 바깥이라 글자 기본 스타일을 받으려고 Material로 감싼다
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
              button: true,
              label: running > 0 ? '변환 $running개 진행 중' : '변환 완료 ${visible.length}개',
              child: GestureDetector(
                key: const Key('convert-fab'),
                onTap: _openSheet,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        key: Key(allDone ? 'convert-fab-done' : 'convert-fab-running'),
                        duration: const Duration(milliseconds: 250),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: allDone ? _doneBg : _runningBg,
                          border: failed > 0 && allDone
                              ? Border.all(color: _failRed, width: 2)
                              : null,
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Icon(
                          allDone ? Icons.done_rounded : Icons.auto_stories_rounded,
                          color: _runningFg,
                          size: 24,
                        ),
                      ),
                      if (!allDone)
                        const SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(strokeWidth: 3, color: _ring),
                        ),
                      if (visible.length > 1)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            key: const Key('convert-fab-count'),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${visible.length}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  void _openSheet() {
    final navContext = widget.router.routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;
    showModalBottomSheet<void>(
      context: navContext,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _JobsSheet(onOpen: (job) {
        Navigator.of(sheetContext).pop();
        _openJob(job);
      }),
    );
  }

  /// 그 기사 상세로 — 변환하던 스타일 탭으로 열리게 먼저 탭을 기록해 둔다
  void _openJob(ConvertJob job) {
    ref.read(articleDetailProvider(job.articleId).notifier).setTab(job.style);
    widget.router.push('/home/article/${job.articleId}');
  }
}

class _JobsSheet extends ConsumerWidget {
  final void Function(ConvertJob) onOpen;
  const _JobsSheet({required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(convertJobsProvider);
    return SafeArea(
      top: false,
      child: Padding(
        key: const Key('convert-jobs-sheet'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('변환 목록', style: AppTextStyles.display(18).copyWith(color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('누르면 그 기사로 이동해요. 확인한 건 목록에서 빠져요.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A9CA3))),
            const SizedBox(height: 12),
            if (jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('진행 중인 변환이 없어요',
                        style: TextStyle(fontSize: 13, color: Color(0xFF9A9CA3)))),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFECEAE4)),
                itemBuilder: (_, i) => _JobTile(job: jobs[i], onTap: () => onOpen(jobs[i])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final ConvertJob job;
  final VoidCallback onTap;
  const _JobTile({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (job.status) {
      ConvertJobStatus.running => ('만드는 중', _runningFg),
      ConvertJobStatus.done => ('완료', const Color(0xFF0B6E64)),
      ConvertJobStatus.failed => ('실패', _failRed),
    };
    return InkWell(
      key: Key('convert-job-${job.articleId}-${job.style}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(_styleLabels[job.style] ?? job.style,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B6E76))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (job.status == ConvertJobStatus.running)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _ring)),
              ),
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
