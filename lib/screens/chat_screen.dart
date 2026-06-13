import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../models/message.dart';
import '../services/groq_service.dart';
import '../services/storage_service.dart';
import '../widgets/message_bubble.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../services/sofascore_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GroqService _groqService = GroqService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _autoSpeak = true;
  bool _showKeyboard = false;
  String _statusText = 'Appuie pour me parler';
  String _liveContext = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );

    _loadMessages();
    _checkApiKey();
    _initSpeech();
    _initTts();
    _fetchLiveContext();
  }

  Future<void> _fetchLiveContext() async {
    try {
      final service = SofascoreService();
      final results = await Future.wait([
        service.getTodayMatches(),
        service.getYesterdayMatches(),
        service.getNews(),
      ]);
      final today = results[0] as List<Match>;
      final yesterday = results[1] as List<Match>;
      final news = results[2] as List<NewsItem>;

      final buf = StringBuffer();

      if (today.isNotEmpty) {
        buf.writeln('Matchs du jour :');
        for (final m in today.take(8)) {
          buf.writeln('- ${m.homeTeam} ${m.scoreDisplay} ${m.awayTeam} (${m.tournament})');
        }
      }
      if (yesterday.isNotEmpty) {
        buf.writeln('Résultats d\'hier :');
        for (final m in yesterday.where((m) => m.isFinished).take(6)) {
          buf.writeln('- ${m.homeTeam} ${m.scoreDisplay} ${m.awayTeam} (${m.tournament})');
        }
      }
      if (news.isNotEmpty) {
        buf.writeln('Dernières news football :');
        for (final n in news.take(8)) {
          buf.writeln('- ${n.headline}');
        }
      }

      if (mounted) setState(() => _liveContext = buf.toString());
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _statusText = 'Appuie pour me parler';
        });
        _stopAnimations();
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _statusText = 'Tina parle...');
      _pulseController.repeat(reverse: true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _statusText = 'Appuie pour me parler');
      _stopAnimations();
    });
  }

  void _stopAnimations() {
    _pulseController.stop();
    _pulseController.reset();
    _ringController.stop();
    _ringController.reset();
  }

  void _checkApiKey() {
    final key = StorageService.getGroqApiKey();
    if (key == null || key.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showApiKeyDialog());
    }
  }

  void _loadMessages() {
    final messages = StorageService.getMessages();
    setState(() => _messages = messages);
    if (_messages.isEmpty) _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcome = ChatMessage(
      id: const Uuid().v4(),
      content: 'Salut Gérard ! Appuie sur le micro pour me parler.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(welcome));
    StorageService.saveMessages(_messages);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusText = 'Appuie pour me parler';
      });
      _stopAnimations();
      if (_controller.text.trim().isNotEmpty) _sendMessage();
    } else {
      if (!_speechAvailable) return;
      await _tts.stop();
      setState(() {
        _isListening = true;
        _statusText = 'J\'écoute...';
      });
      _pulseController.repeat(reverse: true);
      _ringController.repeat();
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _controller.text = result.recognizedWords);
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            setState(() {
              _isListening = false;
              _statusText = 'En train de répondre...';
            });
            _stopAnimations();
            _sendMessage();
          }
        },
        localeId: 'fr-FR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    await _tts.stop();

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _controller.clear();
      _statusText = 'En train de répondre...';
    });
    StorageService.saveMessages(_messages);

    final reply = await _groqService.sendMessage(
      messages: _messages,
      systemPrompt: AppConstants.tinaSystemPrompt,
      liveContext: _liveContext.isNotEmpty ? _liveContext : null,
    );

    final tinaMsg = ChatMessage(
      id: const Uuid().v4(),
      content: reply ?? 'Désolée, je n\'ai pas pu répondre.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tinaMsg);
      _isLoading = false;
      _statusText = _autoSpeak ? 'Tina parle...' : 'Appuie pour me parler';
    });
    StorageService.saveMessages(_messages);

    if (_autoSpeak && reply != null) {
      await _tts.speak(reply);
    } else {
      setState(() => _statusText = 'Appuie pour me parler');
    }
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Conversation', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (_, i) => MessageBubble(message: _messages[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text(
          'Active Tina',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entre ta clé API OpenRouter pour activer Tina.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'sk-or-v1-...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                StorageService.saveGroqApiKey(key);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String get _lastTinaMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (!_messages[i].isUser && _messages[i].content.isNotEmpty) {
        final content = _messages[i].content;
        return content.length > 130 ? '${content.substring(0, 130)}...' : content;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF00BFA5)],
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tina', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('En ligne', style: TextStyle(fontSize: 10, color: AppTheme.primary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _autoSpeak ? Icons.volume_up : Icons.volume_off,
              size: 20,
              color: _autoSpeak ? AppTheme.primary : Colors.white38,
            ),
            onPressed: () => setState(() => _autoSpeak = !_autoSpeak),
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, size: 20, color: Colors.white54),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white54),
            onPressed: () {
              setState(() => _messages = []);
              StorageService.saveMessages([]);
              _addWelcomeMessage();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone centrale : avatar + statut + dernier message
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar animé avec anneau
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anneau externe animé (quand écoute)
                      if (_isListening)
                        AnimatedBuilder(
                          animation: _ringAnimation,
                          builder: (_, __) => Container(
                            width: 140 + (_ringAnimation.value * 40),
                            height: 140 + (_ringAnimation.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(1 - _ringAnimation.value),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      // Avatar principal
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, Color(0xFF00BFA5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(_isListening || _isLoading ? 0.55 : 0.25),
                                blurRadius: _isListening || _isLoading ? 50 : 25,
                                spreadRadius: _isListening || _isLoading ? 8 : 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome, size: 52, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Statut
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isLoading ? 'En train de répondre...' : _statusText,
                    key: ValueKey(_isLoading ? 'loading' : _statusText),
                    style: TextStyle(
                      color: _isListening
                          ? const Color(0xFFFF5252)
                          : _isLoading
                              ? AppTheme.primary
                              : Colors.white60,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Dernier message Tina
                if (_lastTinaMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(
                      _lastTinaMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // Zone contrôles bas
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                // Bouton micro central (grand)
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? const Color(0xFFFF5252) : AppTheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? const Color(0xFFFF5252) : AppTheme.primary)
                              .withOpacity(0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Boutons secondaires
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SecondaryBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Historique',
                      onTap: _showChatHistory,
                    ),
                    _SecondaryBtn(
                      icon: _showKeyboard ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
                      label: 'Clavier',
                      onTap: () => setState(() => _showKeyboard = !_showKeyboard),
                      active: _showKeyboard,
                    ),
                  ],
                ),
                // Champ texte (visible si clavier actif)
                if (_showKeyboard) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Écris à Tina...',
                            hintStyle: TextStyle(color: Colors.white30),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLoading ? Colors.white12 : AppTheme.primary,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _isLoading ? Colors.white24 : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.white.withOpacity(0.07),
              border: Border.all(
                color: active ? AppTheme.primary.withOpacity(0.5) : Colors.white24,
              ),
            ),
            child: Icon(icon, size: 24, color: active ? AppTheme.primary : Colors.white60),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
