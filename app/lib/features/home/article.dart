class Article {
  final int id;
  final String title;
  final String? summary;
  final String category;
  final String publishedAt;
  final String? thumbnailUrl;
  final bool hasCardSummary;

  const Article({
    required this.id,
    required this.title,
    this.summary,
    required this.category,
    required this.publishedAt,
    this.thumbnailUrl,
    required this.hasCardSummary,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      category: json['category'] as String,
      publishedAt: json['publishedAt'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hasCardSummary: json['hasCardSummary'] as bool? ?? false,
    );
  }
}
