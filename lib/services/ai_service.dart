import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class AiService {
  AiService._();
  static final AiService _instance = AiService._();
  factory AiService() => _instance;

  final String _baseUrl = 'https://api.deepseek.com/chat/completions';
  final List<Map<String, String>> _messages = [];
  DateTime? _lastRequestTime;

  void ensureInitialized() {
    if (_messages.isEmpty) {
      _messages.add({
        'role': 'system',
        'content': '''You are "Tour Buddy", a travel assistant for TourEase.
Help users book tours and explain features.
Respond in English, Urdu, or Roman Urdu naturally.''',
      });
    }
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return 'No internet connection. Please check your network and try again.';
      }

      // Simple rate limiting
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest.inSeconds < 1) {
          return 'Please wait a moment...';
        }
      }
      _lastRequestTime = DateTime.now();

      final apiKey =
          dotenv.env['DEEPSEEK_API_KEY'] ??
          'sk-52bc3e9409de4d2fb843528bd78be28e';

      if (apiKey.isEmpty) {
        return 'DeepSeek API key is missing. Please add it to your .env file.';
      }

      // Add user message to history
      _messages.add({'role': 'user', 'content': userMessage});

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'messages': _messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] as String;

        // Add AI response to history
        _messages.add({'role': 'assistant', 'content': aiText});

        return aiText;
      } else {
        debugPrint(
          'DeepSeek API Error: ${response.statusCode} - ${response.body}',
        );
        return 'DeepSeek API Error: ${response.statusCode}. Please check your API key and balance.';
      }
    } catch (e) {
      debugPrint('Unexpected error in AiService: $e');
      return 'Unexpected Error: $e';
    }
  }

  void resetChat() {
    _messages.clear();
    ensureInitialized();
  }

  List<String> getQuickSuggestions() {
    return [
      'Show me popular tours',
      'How does live tracking work?',
      'What payment methods do you accept?',
      'Tell me about Murree tours',
      'How do I contact an agency?',
    ];
  }
}
