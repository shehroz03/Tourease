import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService _instance = GeminiService._();
  factory GeminiService() => _instance;

  GenerativeModel? _model;
  ChatSession? _chatSession;
  DateTime? _lastRequestTime;
  String? _initError;

  void ensureInitialized() {
    if (_model == null) {
      _initialize();
    }
  }

  void _initialize() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        _initError = 'Gemini API key is missing in .env file.';
        debugPrint('GeminiService: $_initError');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content('system', [
          TextPart('''You are "Tour Buddy", a travel assistant for TourEase.
Help users book tours and explain features.
Respond in English, Urdu, or Roman Urdu naturally.'''),
        ]),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
      _startNewSession();
    } catch (e) {
      _initError = 'Failed to initialize AI: $e';
      debugPrint('GeminiService Error: $e');
    }
  }

  void _startNewSession() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String userMessage) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return 'No internet connection. Please check your network and try again.';
      }

      // Simple rate limiting (1 request per 2 seconds)
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastRequestTime!,
        );
        if (timeSinceLastRequest.inSeconds < 2) {
          return 'Please wait a moment before sending another message.';
        }
      }
      _lastRequestTime = DateTime.now();

      // Check if initialized
      if (_initError != null) {
        return _initError!;
      }
      if (_chatSession == null) {
        return 'AI assistant is not ready. Please try again later.';
      }

      // Send message to Gemini
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      // Extract text from response
      final text = response.text;

      if (text == null || text.isEmpty) {
        return 'I apologize, but I couldn\'t generate a response. Please try rephrasing your question.';
      }

      return text;
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API Error: $e');

      // Professional error mapping with raw details
      if (e.message.contains('quota') || e.message.contains('limit')) {
        return 'Rate limit exceeded. Please wait a moment.';
      } else if (e.message.contains('404') || e.message.contains('not found')) {
        return 'AI Model Error (404): ${e.message}';
      } else if (e.message.contains('safety')) {
        return 'I cannot respond due to safety guidelines.';
      } else {
        return 'AI Error: ${e.message}';
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return 'Unexpected Error: $e';
    }
  }

  /// Get quick suggestion responses for common questions
  List<String> getQuickSuggestions() {
    return [
      'Show me popular tours',
      'How does live tracking work?',
      'What payment methods do you accept?',
      'Tell me about Murree tours',
      'How do I contact an agency?',
    ];
  }

  /// Reset chat session (clear history)
  void resetChat() {
    _startNewSession();
  }
}
