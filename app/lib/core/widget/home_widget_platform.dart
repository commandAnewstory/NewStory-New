import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../auth/auth_notifier.dart';
import 'home_widget_service.dart';

const _androidWidgetClass = 'com.newstory.app.TodayCardsWidget';
const _periodicTaskName = 'today-cards-refresh';

/// 1차 목표가 Android라 위젯도 Android만. 그 외 플랫폼(테스트 포함)에선 아무것도 안 하는 구현을 쓴다.
bool get _widgetSupported => !kIsWeb && Platform.isAndroid;

class _HomeWidgetStore implements WidgetStore {
  @override
  Future<T?> read<T>(String key) => HomeWidget.getWidgetData<T>(key);

  @override
  Future<void> save<T>(String key, T? value) => HomeWidget.saveWidgetData<T>(key, value);

  @override
  Future<void> redraw() => HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetClass);
}

class _WorkmanagerScheduler implements WidgetScheduler {
  @override
  Future<void> start() => Workmanager().registerPeriodicTask(
        _periodicTaskName,
        _periodicTaskName,
        frequency: const Duration(hours: 3),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );

  @override
  Future<void> stop() => Workmanager().cancelByUniqueName(_periodicTaskName);
}

class _NoopStore implements WidgetStore {
  @override
  Future<T?> read<T>(String key) async => null;
  @override
  Future<void> save<T>(String key, T? value) async {}
  @override
  Future<void> redraw() async {}
}

class _NoopScheduler implements WidgetScheduler {
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}

Dio _publicDio() => Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ));

HomeWidgetService _createService() => HomeWidgetService(
      fetchCards: todayCardsFetcher(_publicDio()),
      store: _widgetSupported ? _HomeWidgetStore() : _NoopStore(),
      scheduler: _widgetSupported ? _WorkmanagerScheduler() : _NoopScheduler(),
    );

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => _createService());

/// workmanager가 앱이 꺼져 있을 때 별도 isolate에서 부르는 진입점
@pragma('vm:entry-point')
void homeWidgetCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != _periodicTaskName) return true;
    return _createService().refresh();
  });
}

Future<void> initHomeWidgetBackground() async {
  if (!_widgetSupported) return;
  try {
    await Workmanager().initialize(homeWidgetCallbackDispatcher);
  } catch (_) {}
}
