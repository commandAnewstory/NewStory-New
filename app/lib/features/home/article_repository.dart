import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'article.dart';

class ArticleRepository {
  final Dio _dio;

  ArticleRepository(this._dio);

  Future<({List<Article> articles, int totalPages})> fetchArticles({
    required int page,
    required int size,
    String? category,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (category != null && category != '전체') params['category'] = category;

    final response = await _dio.get('/api/articles', queryParameters: params);
    final data = response.data['data'] as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final totalPages = data['totalPages'] as int;

    return (
      articles: content.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList(),
      totalPages: totalPages,
    );
  }
}

final articleRepositoryProvider = Provider<ArticleRepository>(
  (ref) => ArticleRepository(ref.watch(dioProvider)),
);
