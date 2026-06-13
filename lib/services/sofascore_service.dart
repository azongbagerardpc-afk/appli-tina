import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NewsItem {
  final String headline;
  final String? description;

  NewsItem({required this.headline, this.description});
}

class Match {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final String tournament;
  final DateTime? startTime;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.tournament,
    this.startTime,
  });

  bool get isFinished => status == 'finished';
  bool get isLive => status == 'inprogress';

  String get scoreDisplay {
    if (homeScore != null && awayScore != null) return '$homeScore - $awayScore';
    if (startTime != null) return DateFormat('HH:mm').format(startTime!.toLocal());
    return 'vs';
  }

  String get scriptTopic => '$homeTeam vs $awayTeam ($scoreDisplay) - $tournament';
}

class SofascoreService {
  static const String _baseUrl =
      'https://site.api.espn.com/apis/site/v2/sports/soccer';

  static const Map<String, String> _leagues = {
    'fifa.world': 'Coupe du Monde 2026',
    'eng.1': 'Premier League',
    'esp.1': 'La Liga',
    'ger.1': 'Bundesliga',
    'ita.1': 'Serie A',
    'fra.1': 'Ligue 1',
    'uefa.champions': 'Ligue des Champions',
    'uefa.europa': 'Europa League',
    'usa.1': 'MLS',
  };

  Future<List<Match>> getTodayMatches() async {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return _getMatchesByDate(date);
  }

  Future<List<Match>> getYesterdayMatches() async {
    final date = DateFormat('yyyyMMdd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    return _getMatchesByDate(date);
  }

  Future<List<Match>> _getMatchesByDate(String date) async {
    final futures = _leagues.entries
        .map((e) => _fetchLeague(e.key, e.value, date))
        .toList();
    final results = await Future.wait(futures);
    final matches = results.expand((e) => e).toList();
    matches.sort((a, b) {
      const order = {'inprogress': 0, 'finished': 1, 'notstarted': 2};
      return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
    });
    return matches;
  }

  Future<List<Match>> _fetchLeague(
      String slug, String leagueName, String date) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$slug/scoreboard?dates=$date'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = (data['events'] as List?) ?? [];
        return events
            .map((e) => _parseEvent(e, leagueName))
            .whereType<Match>()
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<NewsItem>> getNews() async {
    final List<NewsItem> allNews = [];
    final slugs = ['fifa.world', 'eng.1', 'esp.1', 'uefa.champions'];
    for (final slug in slugs) {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/$slug/news?limit=5'))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final articles = (data['articles'] as List?) ?? [];
          for (final a in articles) {
            final headline = a['headline'] as String?;
            if (headline != null && headline.isNotEmpty) {
              allNews.add(NewsItem(
                headline: headline,
                description: a['description'] as String?,
              ));
            }
          }
        }
      } catch (_) {}
    }
    return allNews;
  }

  Match? _parseEvent(dynamic event, String leagueName) {
    try {
      final competitions = (event['competitions'] as List?);
      if (competitions == null || competitions.isEmpty) return null;
      final competition = competitions.first as Map<String, dynamic>;

      final competitors = (competition['competitors'] as List?) ?? [];
      if (competitors.length < 2) return null;

      final home = competitors.firstWhere(
        (c) => c['homeAway'] == 'home',
        orElse: () => competitors[0],
      ) as Map<String, dynamic>;
      final away = competitors.firstWhere(
        (c) => c['homeAway'] == 'away',
        orElse: () => competitors[1],
      ) as Map<String, dynamic>;

      final statusType =
          (competition['status'] as Map?)?['type'] as Map<String, dynamic>?;
      final espnState = statusType?['state'] as String? ?? 'pre';

      final statusNormalized = espnState == 'post'
          ? 'finished'
          : espnState == 'in'
              ? 'inprogress'
              : 'notstarted';

      final hasScore = espnState != 'pre';
      final homeScore =
          hasScore ? int.tryParse(home['score']?.toString() ?? '') : null;
      final awayScore =
          hasScore ? int.tryParse(away['score']?.toString() ?? '') : null;

      final dateStr = event['date'] as String?;

      return Match(
        id: event['id']?.toString() ?? '',
        homeTeam: (home['team'] as Map?)?['displayName'] as String? ?? 'Équipe A',
        awayTeam: (away['team'] as Map?)?['displayName'] as String? ?? 'Équipe B',
        homeScore: homeScore,
        awayScore: awayScore,
        status: statusNormalized,
        tournament: leagueName,
        startTime: dateStr != null ? DateTime.parse(dateStr) : null,
      );
    } catch (_) {
      return null;
    }
  }
}
