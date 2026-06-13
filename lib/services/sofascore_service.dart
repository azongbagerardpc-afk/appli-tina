import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Match {
  final int id;
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
    return 'vs';
  }

  String get scriptTopic =>
      '$homeTeam vs $awayTeam ($scoreDisplay) - $tournament';

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? 0,
      homeTeam: (json['homeTeam'] ?? {})['name'] ?? 'Équipe A',
      awayTeam: (json['awayTeam'] ?? {})['name'] ?? 'Équipe B',
      homeScore: json['homeScore']?['current'],
      awayScore: json['awayScore']?['current'],
      status: (json['status'] ?? {})['type'] ?? 'notstarted',
      tournament: (json['tournament'] ?? {})['name'] ?? 'Compétition',
      startTime: json['startTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTimestamp'] * 1000)
          : null,
    );
  }
}

class SofascoreService {
  static const String _baseUrl = 'https://api.sofascore.com/api/v1';
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Pixel 4a) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'fr-FR,fr;q=0.9',
  };

  static const List<String> _topLeagueKeywords = [
    'premier league', 'la liga', 'bundesliga', 'serie a', 'ligue 1',
    'champions league', 'europa league', 'conference league',
    'world cup', 'coupe du monde', 'africa cup', 'afcon', 'can',
    'copa del rey', 'fa cup', 'coupe de france', 'coppa italia',
    'mls', 'liga mx', 'eredivisie', 'primeira liga', 'super lig',
    'nations league', 'ligue des nations',
  ];

  Future<List<Match>> getTodayMatches() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _getMatchesByDate(date);
  }

  Future<List<Match>> getYesterdayMatches() async {
    final date = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    return _getMatchesByDate(date);
  }

  Future<List<Match>> _getMatchesByDate(String date) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/sport/football/scheduled-events/$date'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = (data['events'] as List?) ?? [];
        final matches = events.map((e) => Match.fromJson(e)).toList();
        return matches
            .where((m) => _isTopLeague(m.tournament))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  bool _isTopLeague(String tournament) {
    final lower = tournament.toLowerCase();
    return _topLeagueKeywords.any((kw) => lower.contains(kw));
  }
}
