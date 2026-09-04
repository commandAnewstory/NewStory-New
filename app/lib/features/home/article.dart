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
      title: json['title'] as String,
      description: json['description'] as String?,
      url: json['url'] as String,
      source: json['source'] as String?,
      category: json['category'] as String,
      publishedAt: json['publishedAt'] as String,
    );
  }
}
