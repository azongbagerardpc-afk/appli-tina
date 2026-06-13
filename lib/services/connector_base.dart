abstract class BaseConnector {
  String get name;
  String get description;
}

abstract class NewsConnector extends BaseConnector {
  Future<List<NewsArticle>> fetchNews({int limit = 20});
}

class NewsArticle {
  final String title;
  final String? summary;
  final String? url;
  final String? source;

  const NewsArticle({
    required this.title,
    this.summary,
    this.url,
    this.source,
  });
}
