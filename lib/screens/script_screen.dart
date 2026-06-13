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

  static const List<({String label, IconData icon})> _quickTopics = [
    (label: 'Geste viral d\'un joueur', icon: Icons.sports_soccer),
    (label: 'Polémique arbitrage ou VAR', icon: Icons.gavel),
    (label: 'Transfert inattendu ou choc', icon: Icons.swap_horiz_rounded),
    (label: 'Défaite surprise d\'un grand club', icon: Icons.trending_down),
    (label: 'Record battu ou stat folle', icon: Icons.bar_chart),
    (label: 'Incident insolite sur le terrain', icon: Icons.warning_amber_rounded),
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
      const SnackBar(content: Text('Script copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripts TikTok'),
        actions: [
          if (_script != null) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: _copyScript,
              tooltip: 'Copier',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  size: 20, color: AppTheme.textTertiary),
              onPressed: () =>
                  _generate(_currentTopic ?? _controller.text),
              tooltip: 'Régénérer',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ sujet
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUJET DU SCRIPT',
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText:
                                'Ex: Messi offre ses maillots aux fans togolais',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (v) => _generate(v.trim()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _generate(_controller.text.trim()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Go',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sujets rapides
            const Text(
              'SUJETS RAPIDES',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTopics
                  .map((t) => GestureDetector(
                        onTap: () => _generate(t.label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            border: Border.all(
                                color: AppTheme.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.icon,
                                  size: 13,
                                  color: AppTheme.primary),
                              const SizedBox(width: 5),
                              Text(
                                t.label,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),

            // États : loading / script / vide
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tina génère ton script...',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ça prend 5 à 15 secondes',
                      style: TextStyle(
                          color: AppTheme.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              )
            else if (_script != null) ...[
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Script prêt',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    '${_script!.length} car.',
                    style: TextStyle(
                      color: _script!.length > 1800
                          ? const Color(0xFFEF4444)
                          : AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  _script!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.65),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyScript,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copier'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _generate(_currentTopic ?? _controller.text),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: AppTheme.textSecondary),
                    label: const Text(
                      'Régénérer',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
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
