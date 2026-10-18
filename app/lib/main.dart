import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/auth/auth_notifier.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widget/home_widget_platform.dart';
import 'core/widget/home_widget_service.dart';
import 'core/widget/home_widget_sync.dart';

const _kakaoNativeAppKey = String.fromEnvironment(
  'KAKAO_NATIVE_APP_KEY',
  defaultValue: 'c4e8a62cbf905af0756f20a522b1b162',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: _kakaoNativeAppKey);
  final container = ProviderContainer();
  await container.read(authProvider.notifier).init();
  await initHomeWidgetBackground();
  unawaited(container.read(homeWidgetStartupSyncProvider)());
  runApp(UncontrolledProviderScope(container: container, child: const NewStoryApp()));
}

class NewStoryApp extends ConsumerStatefulWidget {
  const NewStoryApp({super.key});

  @override
  ConsumerState<NewStoryApp> createState() => _NewStoryAppState();
}

class _NewStoryAppState extends ConsumerState<NewStoryApp> {
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    // 위젯 "관심 뉴스" 줄을 눌러 앱이 열린 경우: 꺼져 있다 켜졌을 때 + 켜져 있을 때 둘 다
    final source = ref.read(widgetLaunchSourceProvider);
    source.initial().then(_openFromWidget);
    _widgetClicks = source.clicks.listen(_openFromWidget);
  }

  void _openFromWidget(Uri? uri) {
    final location = widgetUriToLocation(uri);
    if (location == null || !mounted) return;
    // 로그아웃 상태면 라우터 redirect가 로그인 화면으로 보낸다
    ref.read(routerProvider).go(location);
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'NewStory',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
