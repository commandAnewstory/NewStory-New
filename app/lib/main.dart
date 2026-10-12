import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'core/auth/auth_notifier.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widget/home_widget_platform.dart';
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

class NewStoryApp extends ConsumerWidget {
  const NewStoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'NewStory',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
