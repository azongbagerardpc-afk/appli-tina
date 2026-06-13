import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/groq_service.dart';
import '../config/theme.dart';

class ScriptScreen extends StatefulWidget {
  const ScriptScreen({super.key});

  @override
  State<ScriptScreen> createState() => _ScriptScreenState();
}

class _ScriptScreenState extends State<ScriptScreen> {
  final TextEditingController _controller = TextEditingController();
  final GroqService _groqService = GroqService();
  String? _script;
  bool _isLoading = false;
  String? _currentTopic;

  static const List<String> _quickTopics = [
    'Geste viral d\'un joueur après un match',
    'Polémique arbitrage ou VAR',
    'Transfert inattendu ou choc',
    'Défaite surprise d\'un grand club',
    'Record battu ou statistique folle',
    'Incident insolite sur ou hors du terrain',
  ];

  Future<void> _generate(String topic) async {
    if (_isLoading || topic.isEmpty) return;
    setState(() {
      _isLoading = true;
      _script = null;
      _currentTopic = topic;
    });

    final script = await _groqService.generateScript(topic);

    setState(() {
      _script = script;
      _isLoading = false;
    });
  }

  void _copyScript() {
    if (_script == null) return;
    Clipboard.setData(ClipboardData(text: _script!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Script copié dans le presse-papiers'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Générateur de scripts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quel est le sujet ?',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Messi donne ses maillots aux Mauritaniens',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                    onSubmitted: (v) => _generate(v.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _generate(_controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'SUJETS RAPIDES',
              style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTopics
                  .map((topic) => GestureDetector(
                        onTap: () => _generate(topic),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.35)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            topic,
                            style: TextStyle(
                                color: AppTheme.primary, fontSize: 12),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 14),
                    Text(
                      'Tina génère ton script...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
            else if (_script != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Script prêt',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy,
                            color: AppTheme.primary, size: 20),
                        onPressed: _copyScript,
                        tooltip: 'Copier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white38, size: 20),
                        onPressed: () =>
                            _generate(_currentTopic ?? _controller.text),
                        tooltip: 'Régénérer',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  _script!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.65),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _copyScript,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier le script complet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
