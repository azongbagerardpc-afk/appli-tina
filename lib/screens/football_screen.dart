import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sofascore_service.dart';
import '../services/groq_service.dart';
import '../config/theme.dart';

class FootballScreen extends StatefulWidget {
  const FootballScreen({super.key});

  @override
  State<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen>
    with SingleTickerProviderStateMixin {
  final SofascoreService _sofascore = SofascoreService();
  List<Match> _todayMatches = [];
  List<Match> _yesterdayMatches = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _sofascore.getTodayMatches(),
      _sofascore.getYesterdayMatches(),
    ]);
    setState(() {
      _todayMatches = results[0];
      _yesterdayMatches = results[1];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadMatches),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: "Aujourd'hui"),
            Tab(text: 'Hier'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _MatchList(
                    matches: _todayMatches, onRefresh: _loadMatches),
                _MatchList(
                    matches: _yesterdayMatches, onRefresh: _loadMatches),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _MatchList extends StatelessWidget {
  final List<Match> matches;
  final Future<void> Function() onRefresh;

  const _MatchList({required this.matches, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, color: Colors.white12, size: 48),
            SizedBox(height: 12),
            Text('Aucun match trouvé',
                style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      grouped.putIfAbsent(m.tournament, () => []).add(m);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: grouped.length,
        itemBuilder: (ctx, i) {
          final tournament = grouped.keys.elementAt(i);
          return _TournamentSection(
            tournament: tournament,
            matches: grouped[tournament]!,
          );
        },
      ),
    );
  }
}

class _TournamentSection extends StatelessWidget {
  final String tournament;
  final List<Match> matches;

  const _TournamentSection(
      {required this.tournament, required this.matches});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(
            tournament.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...matches.map((m) => _MatchCard(match: m)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                match.homeTeam,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: match.isLive
                    ? Colors.red.withOpacity(0.15)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: match.isLive
                    ? Border.all(color: Colors.red.withOpacity(0.4))
                    : null,
              ),
              child: Text(
                match.scoreDisplay,
                style: TextStyle(
                  color: match.isLive ? Colors.red : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                match.awayTeam,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (match.isFinished)
              IconButton(
                icon: const Icon(Icons.auto_awesome,
                    color: AppTheme.primary, size: 18),
                tooltip: 'Générer un script',
                onPressed: () => _showScriptDialog(context, match),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  void _showScriptDialog(BuildContext context, Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScriptFromMatchScreen(match: match),
      ),
    );
  }
}

class _ScriptFromMatchScreen extends StatefulWidget {
  final Match match;
  const _ScriptFromMatchScreen({required this.match});

  @override
  State<_ScriptFromMatchScreen> createState() =>
      _ScriptFromMatchScreenState();
}

class _ScriptFromMatchScreenState extends State<_ScriptFromMatchScreen> {
  final GroqService _groq = GroqService();
  String? _script;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    final s = await _groq.generateScript(widget.match.scriptTopic);
    setState(() {
      _script = s;
      _isLoading = false;
    });
  }

  void _copy() {
    if (_script == null) return;
    Clipboard.setData(ClipboardData(text: _script!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Script copié'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          if (!_isLoading && _script != null)
            IconButton(
                icon: const Icon(Icons.copy), onPressed: _copy),
          IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _generate),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Tina génère le script...',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: SelectableText(
                      _script ?? 'Erreur lors de la génération.',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copier le script'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
