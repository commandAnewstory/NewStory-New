class Article {
  final int id;
  final String title;
  final String? description;
  final String url;
  final String? source;
  final String category;
  final String publishedAt;

  const Article({
    required this.id,
    required this.title,
    this.description,
    required this.url,
    this.source,
    required this.category,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      url: json['url'] as String? ?? '',
      source: json['source'] as String?,
      // 직접 변환으로 저장된 기사는 카테고리·발행시각이 없다 — 한 건 때문에 목록 전체가 실패하지 않게
      category: json['category'] as String? ?? '',
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }
}
