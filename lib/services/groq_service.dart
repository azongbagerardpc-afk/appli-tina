import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class GroqService {
  Future<String?> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
    int retryCount = 0,
  }) async {
    final apiKey = StorageService.getGroqApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Clé API manquante. Appuie sur l\'icône clé pour la configurer.';
    }

    final recentMessages = messages.length > 10
        ? messages.sublist(messages.length - 10)
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
            'maxOutputTokens': 800,
            'temperature': 0.7,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else if (response.statusCode == 429) {
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 30));
          return sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            retryCount: retryCount + 1,
          );
        }
        return 'Trop de messages d\'un coup. Attends 1 minute et réessaie.';
      } else if (response.statusCode == 400) {
        return 'Clé API invalide. Appuie sur l\'icône clé pour la reconfigurer.';
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
