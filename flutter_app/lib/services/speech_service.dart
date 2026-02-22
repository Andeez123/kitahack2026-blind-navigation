import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  Function(String)? onResult;

  Future<bool> initialize() async {
    final available = await _speech.initialize();
    
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(1.0);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    return available;
  }

  void startListening(Function(String) onResult) {
    if (_isListening) return;
    this.onResult = onResult;
    _isListening = true;
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final transcript = result.recognizedWords.toLowerCase();
          if (transcript.contains('start') || 
              transcript.contains('hi') || 
              transcript.contains('hello')) {
            onResult(transcript);
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopListening() {
    if (!_isListening) return;
    _speech.stop();
    _isListening = false;
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
