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

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': AppConstants.groqModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ...recentMessages.map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            }),
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        return 'Clé API invalide. Vérifie ta clé sur groq.com.';
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
