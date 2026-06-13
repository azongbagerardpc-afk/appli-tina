import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class GroqService {
  static DateTime? _lastRequestTime;

  Future<String?> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
    int retryCount = 0,
  }) async {
    final apiKey = StorageService.getGroqApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Clé API manquante. Appuie sur l\'icône clé pour la configurer.';
    }

    // Anti-burst : minimum 4 secondes entre chaque requête
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final elapsed = now.difference(_lastRequestTime!);
      if (elapsed.inMilliseconds < 4000) {
        await Future.delayed(
            Duration(milliseconds: 4000 - elapsed.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();

    // Envoyer seulement les 3 derniers messages pour économiser le quota
    final recentMessages =
        messages.length > 3 ? messages.sublist(messages.length - 3) : messages;

    final contents = recentMessages
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [
                {'text': m.content}
              ],
            })
        .toList();

    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.geminiBaseUrl}?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'system_instruction': {
                'parts': [{'text': systemPrompt}],
              },
              'contents': contents,
              'generationConfig': {
                'maxOutputTokens': 500,
                'temperature': 0.7,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else if (response.statusCode == 429) {
        if (retryCount < 3) {
          await Future.delayed(const Duration(seconds: 15));
          return sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            retryCount: retryCount + 1,
          );
        }
        return 'Trop de messages en peu de temps. Attends 1 minute et réessaie.';
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        return 'Clé API invalide. Appuie sur l\'icône clé en haut à droite pour la reconfigurer.';
      } else {
        return 'Erreur réseau (${response.statusCode}). Réessaie dans quelques secondes.';
      }
    } catch (e) {
      return 'Pas de connexion internet. Vérifie ton réseau et réessaie.';
    }
  }

  Future<String?> generateScript(String topic) async {
    final tempMessage = [
      ChatMessage(
        id: 'temp',
        content: 'Génère un script TikTok viral sur ce sujet : $topic',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
    return sendMessage(
      messages: tempMessage,
      systemPrompt: AppConstants.scriptSystemPrompt,
    );
  }
}
