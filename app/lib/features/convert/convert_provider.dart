import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../article/article_detail_provider.dart';

class ConvertState {
  final String url;
  final String? selectedStyle;
  final bool isConverting;
  final ConvertResult? result;
  final String? error;

  const ConvertState({
    this.url = '',
    this.selectedStyle,
    this.isConverting = false,
    this.result,
    this.error,
  });

  bool get canConvert =>
      url.trim().isNotEmpty && selectedStyle != null && !isConverting;

  ConvertState copyWith({
    String? url,
    String? selectedStyle,
    bool clearStyle = false,
    bool? isConverting,
    ConvertResult? result,
    bool clearResult = false,
    String? error,
  }) {
    return ConvertState(
      url: url ?? this.url,
      selectedStyle: clearStyle ? null : (selectedStyle ?? this.selectedStyle),
      isConverting: isConverting ?? this.isConverting,
      result: clearResult ? null : (result ?? this.result),
      error: error,
    );
  }
}

class ConvertNotifier extends StateNotifier<ConvertState> {
  final Dio _dio;

  ConvertNotifier(this._dio) : super(const ConvertState());

  void setUrl(String url) {
    state = state.copyWith(url: url, clearResult: true, error: null);
  }

  void setStyle(String style) {
    state = state.copyWith(selectedStyle: style, clearResult: true, error: null);
  }

  Future<void> convert() async {
    if (!state.canConvert) return;
    state = state.copyWith(isConverting: true, clearResult: true, error: null);
    try {
      final response = await _dio.post('/api/convert', data: {
        'url': state.url.trim(),
        'style': state.selectedStyle,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final glossaryRaw = data['glossary'] as List<dynamic>? ?? [];
      final result = ConvertResult(
        convertedText: data['convertedText'] as String,
        glossary: glossaryRaw
            .map((e) => GlossaryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        readingTimeLabel: data['readingTimeLabel'] as String?,
      );
      state = state.copyWith(isConverting: false, result: result);
    } catch (e) {
      state = state.copyWith(
          isConverting: false, error: '변환에 실패했습니다. URL을 확인하고 다시 시도해 주세요.');
    }
  }

  void retry() => convert();
}

final convertProvider =
    StateNotifierProvider<ConvertNotifier, ConvertState>(
  (ref) => ConvertNotifier(ref.watch(dioProvider)),
);
