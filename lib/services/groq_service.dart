import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class GroqService {
  Future<String?> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
    String? liveContext,
    int retryCount = 0,
  }) async {
    final effectivePrompt = (liveContext != null && liveContext.isNotEmpty)
        ? '$systemPrompt\n\nACTUALITÉS FOOTBALL EN COURS (mis à jour automatiquement) :\n$liveContext'
        : systemPrompt;
    final apiKey = StorageService.getGroqApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Clé API manquante. Appuie sur l\'icône clé pour la configurer.';
    }

    final recentMessages =
        messages.length > 6 ? messages.sublist(messages.length - 6) : messages;

    final openAiMessages = [
      {'role': 'system', 'content': effectivePrompt},
      ...recentMessages.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
    ];

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.openRouterUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://github.com/azongbagerardpc-afk/appli-tina',
              'X-Title': 'Tina',
            },
            body: json.encode({
              'model': AppConstants.openRouterModel,
              'messages': openAiMessages,
              'max_tokens': 800,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String?;
      } else if (response.statusCode == 429) {
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 10));
          return sendMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            liveContext: liveContext,
            retryCount: retryCount + 1,
          );
        }
        return 'Trop de messages. Attends quelques secondes et réessaie.';
      } else if (response.statusCode == 401) {
        return 'Clé API invalide. Appuie sur l\'icône clé en haut à droite.';
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
