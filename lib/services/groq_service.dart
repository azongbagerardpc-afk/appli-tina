import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class GroqService {
  Future<String?> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
  }) async {
    final apiKey = StorageService.getGroqApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Clé API manquante. Appuie sur l\'icône clé pour la configurer.';
    }

    final recentMessages = messages.length > 20
        ? messages.sublist(messages.length - 20)
        : messages;

    final contents = recentMessages.map((m) => {
      'role': m.isUser ? 'user' : 'model',
      'parts': [{'text': m.content}],
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.geminiBaseUrl}?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'system_instruction': {
            'parts': [{'text': systemPrompt}],
          },
          'contents': contents,
          'generationConfig': {
            'maxOutputTokens': 1024,
            'temperature': 0.7,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else if (response.statusCode == 400) {
        return 'Clé API invalide. Vérifie ta clé Gemini.';
      } else {
        return 'Erreur API (${response.statusCode}). Réessaie dans quelques secondes.';
      }
    } catch (e) {
      return 'Erreur de connexion. Vérifie ta connexion internet.';
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
