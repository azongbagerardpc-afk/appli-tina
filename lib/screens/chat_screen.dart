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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqService _groqService = GroqService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _autoSpeak = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkApiKey();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
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
      content: 'Salut Gérard ! Je suis Tina. Écris-moi ou appuie sur le micro pour me parler.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(welcome));
    StorageService.saveMessages(_messages);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_controller.text.trim().isNotEmpty) _sendMessage();
    } else {
      if (!_speechAvailable) return;
      await _tts.stop();
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            setState(() => _isListening = false);
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
    });
    StorageService.saveMessages(_messages);
    _scrollToBottom();

    final reply = await _groqService.sendMessage(
      messages: _messages,
      systemPrompt: AppConstants.tinaSystemPrompt,
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
    });
    StorageService.saveMessages(_messages);
    _scrollToBottom();

    if (_autoSpeak && reply != null) {
      await _tts.speak(reply);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF00BFA5)],
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tina', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('En ligne', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
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
            tooltip: 'Voix Tina',
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, size: 20),
            onPressed: _showApiKeyDialog,
            tooltip: 'Clé API',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              setState(() => _messages = []);
              StorageService.saveMessages([]);
              _addWelcomeMessage();
            },
            tooltip: 'Effacer',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return const TypingIndicator();
                return MessageBubble(message: _messages[i]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // Bouton micro
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Colors.red.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: _isListening ? Colors.red : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 20,
                color: _isListening ? Colors.red : Colors.white54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isListening ? 'J\'écoute...' : 'Dis quelque chose à Tina...',
                hintStyle: TextStyle(
                  color: _isListening ? Colors.red.withOpacity(0.5) : Colors.white30,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton envoyer
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
