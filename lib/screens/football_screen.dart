import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sofascore_service.dart';
import '../services/french_news_service.dart';
import '../services/connector_base.dart';
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
  final FrenchNewsService _newsService = FrenchNewsService();
  List<Match> _todayMatches = [];
  List<Match> _yesterdayMatches = [];
  List<NewsArticle> _news = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _sofascore.getTodayMatches(),
      _sofascore.getYesterdayMatches(),
      _newsService.fetchNews(limit: 20),
    ]);
    setState(() {
      _todayMatches = results[0] as List<Match>;
      _yesterdayMatches = results[1] as List<Match>;
      _news = results[2] as List<NewsArticle>;
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
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadAll,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textTertiary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Aujourd'hui"),
                Tab(text: 'Hier'),
                Tab(text: 'Actualités'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _MatchList(matches: _todayMatches, onRefresh: _loadAll),
                _MatchList(matches: _yesterdayMatches, onRefresh: _loadAll),
                _NewsList(news: _news, onRefresh: _loadAll),
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

class _NewsList extends StatelessWidget {
  final List<NewsArticle> news;
  final Future<void> Function() onRefresh;
  const _NewsList({required this.news, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceVariant,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.newspaper_rounded,
                  color: AppTheme.textTertiary, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Aucune actualité disponible',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Tire vers le bas pour actualiser',
                style: TextStyle(
                    color: AppTheme.textTertiary, fontSize: 12)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: news.length,
        itemBuilder: (ctx, i) {
          final item = news[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.source != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.source!.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (item.summary != null &&
                          item.summary!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            _ScriptFromNewsScreen(news: item),
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: AppTheme.primary, size: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'Générer un script',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textTertiary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScriptFromNewsScreen extends StatefulWidget {
  final NewsArticle news;
  const _ScriptFromNewsScreen({required this.news});

  @override
  State<_ScriptFromNewsScreen> createState() =>
      _ScriptFromNewsScreenState();
}

class _ScriptFromNewsScreenState extends State<_ScriptFromNewsScreen> {
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
    final topic = widget.news.summary != null
        ? '${widget.news.title}. ${widget.news.summary}'
        : widget.news.title;
    final s = await _groq.generateScript(topic);
    setState(() {
      _script = s;
      _isLoading = false;
    });
  }

  void _copy() {
    if (_script == null) return;
    Clipboard.setData(ClipboardData(text: _script!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Script', style: TextStyle(fontSize: 15)),
        actions: [
          if (!_isLoading && _script != null)
            IconButton(
                icon: const Icon(Icons.copy_rounded), onPressed: _copy),
          IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
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
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      widget.news.title,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25)),
                    ),
                    child: SelectableText(
                      _script ?? 'Erreur lors de la génération.',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copier le script'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<Match> matches;
  final Future<void> Function() onRefresh;

  const _MatchList({required this.matches, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceVariant,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.sports_soccer,
                  color: AppTheme.textTertiary, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Aucun match trouvé',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
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
      backgroundColor: AppTheme.surface,
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
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tournament.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.isLive
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: match.isLive
                    ? const Color(0xFFEF4444).withOpacity(0.12)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: match.isLive
                    ? Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.4))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (match.isLive) ...[
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                  Text(
                    match.scoreDisplay,
                    style: TextStyle(
                      color: match.isLive
                          ? const Color(0xFFEF4444)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
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
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ScriptFromMatchScreen(match: match),
                  ),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.primary, size: 15),
                ),
              )
            else
              const SizedBox(width: 38),
          ],
        ),
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
      const SnackBar(content: Text('Script copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.match.homeTeam} vs ${widget.match.awayTeam}',
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_isLoading && _script != null)
            IconButton(
                icon: const Icon(Icons.copy_rounded), onPressed: _copy),
          IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
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
                      style: TextStyle(color: AppTheme.textSecondary)),
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
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25)),
                    ),
                    child: SelectableText(
                      _script ?? 'Erreur lors de la génération.',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copier le script'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
