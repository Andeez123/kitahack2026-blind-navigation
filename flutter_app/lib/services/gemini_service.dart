import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../types.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final GenerativeModel _ttsModel;
  final String apiKey;
  ChatSession? _session;
  
  static const String modelName = 'gemini-2.5-flash-native-audio-preview-12-2025';
  static const String ttsModelName = 'gemini-2.5-flash-preview-tts';
  static const String agentVoice = 'Kore';

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
    _ttsModel = GenerativeModel(
      model: ttsModelName,
      apiKey: apiKey,
    );
  }

  // Note: The Live API is not directly available in the Dart SDK
  // This is a simplified implementation using the standard API
  // For full Live API support, you would need to use HTTP requests directly
  
  Future<void> startSession({
    required Function(String) onText,
    required Function(Uint8List) onAudio,
    required Location? location,
  }) async {
    // Initialize session with system instruction
    final systemInstruction = Content.system(
      'You are VisionGuide AI, a real-time navigation expert for the blind. '
      '1. BE CONCISE. Do not use long sentences. '
      '2. IMMEDIATELY start by asking: "Where would you like to go today?" '
      '3. Use search_place and get_directions tools as soon as possible. '
      '4. When navigating, provide small, punchy walking instructions (e.g., "Left in 10 steps", "Stay straight"). '
      '5. PRIORITIZE SAFETY. If you see hazards (poles, drops, people), say "STOP" or "WATCH OUT" immediately. '
      '6. User location: ${location != null ? "${location.latitude},${location.longitude}" : "Unknown"}.',
    );

    _session = _model.startChat(
      history: [systemInstruction],
    );
  }

  Future<void> sendImage(Uint8List imageBytes) async {
    if (_session == null) return;
    
    try {
      final response = await _session!.sendMessage(
        Content.multi([
          DataPart('image/jpeg', imageBytes),
        ]),
      );
      
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        // Handle text response
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendAudio(Uint8List audioBytes) async {
    if (_session == null) return;
    
    try {
      final response = await _session!.sendMessage(
        Content.multi([
          DataPart('audio/pcm', audioBytes),
        ]),
      );
      
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        // Handle text response
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<Uint8List?> generateTTS(String text) async {
    try {
      // Using HTTP API for TTS since it's not in the Dart SDK
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$ttsModelName:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': text}]}],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': agentVoice}
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Audio = data['candidates']?[0]?['content']?['parts']?[0]?['inlineData']?['data'];
        if (base64Audio != null) {
          return base64Decode(base64Audio);
        }
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  void stopSession() {
    _session = null;
  }
}
