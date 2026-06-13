import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connector_base.dart';

class FrenchNewsService implements NewsConnector {
  @override
  String get name => 'Actualités FR';

  @override
  String get description => 'Flux RSS football francophone (L\'Équipe)';

  static const _primaryFeed =
      'https://www.lequipe.fr/rss/actu_rss_Football.xml';
  static const _fallbackFeed =
      'https://news.google.com/rss/search?q=football+ligue1+ldc+psg&hl=fr&gl=FR&ceid=FR:fr';

  @override
  Future<List<NewsArticle>> fetchNews({int limit = 20}) async {
    for (final url in [_primaryFeed, _fallbackFeed]) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'TinaApp/1.0'})
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final items = _parseRss(utf8.decode(response.bodyBytes));
          if (items.isNotEmpty) return items.take(limit).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  List<NewsArticle> _parseRss(String xml) {
    final items = <NewsArticle>[];
    final itemRx = RegExp(r'<item[^>]*>(.*?)</item>', dotAll: true);
    final titleRx = RegExp(
        r'<title[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>',
        dotAll: true);
    final descRx = RegExp(
        r'<description[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>',
        dotAll: true);

    for (final m in itemRx.allMatches(xml)) {
      final block = m.group(1) ?? '';
      final title = _clean(titleRx.firstMatch(block)?.group(1) ?? '');
      if (title.isEmpty) continue;
      final desc = _clean(descRx.firstMatch(block)?.group(1) ?? '');
      items.add(NewsArticle(
        title: title,
        summary: desc.isNotEmpty ? desc : null,
        source: 'L\'Équipe',
      ));
    }
    return items;
  }

  String _clean(String s) => s
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
