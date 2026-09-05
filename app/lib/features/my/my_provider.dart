import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/auth/auth_notifier.dart';

class UserProfile {
  final int id;
  final String email;
  final String nickname;
  final String lastGlossaryLevel;
  final bool widgetEnabled;

  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.lastGlossaryLevel,
    required this.widgetEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        nickname: json['nickname'] as String,
        lastGlossaryLevel: json['lastGlossaryLevel'] as String,
        widgetEnabled: json['widgetEnabled'] as bool,
      );

  UserProfile copyWith({bool? widgetEnabled}) => UserProfile(
        id: id,
        email: email,
        nickname: nickname,
        lastGlossaryLevel: lastGlossaryLevel,
        widgetEnabled: widgetEnabled ?? this.widgetEnabled,
      );
}

class MyState {
  final UserProfile? profile;
  final bool isLoading;

  const MyState({this.profile, this.isLoading = true});

  MyState copyWith({UserProfile? profile, bool? isLoading}) => MyState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
      );
}

class MyNotifier extends StateNotifier<MyState> {
  final Dio _dio;
  final AuthNotifier _auth;

  MyNotifier(this._dio, this._auth) : super(const MyState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _dio.get('/api/users/me');
      state = MyState(
        profile: UserProfile.fromJson(res.data['data'] as Map<String, dynamic>),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setWidgetEnabled(bool enabled) async {
    final prev = state.profile;
    if (prev == null) return;
    state = state.copyWith(profile: prev.copyWith(widgetEnabled: enabled));
    try {
      await _dio.patch('/api/users/me', data: {'widgetEnabled': enabled});
    } catch (_) {
      state = state.copyWith(profile: prev);
    }
  }

  Future<void> logout() async {
    await _auth.logout();
  }
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(ref.watch(dioProvider), ref.read(authProvider.notifier)),
);
