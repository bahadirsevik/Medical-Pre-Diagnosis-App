import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  bool get isListening => _isListening;

  AudioService() {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setPitch(1.0);
  }

  Future<bool> initSpeech() async {
    return await _speech.initialize(
      onStatus: (status) => print('STT Status: $status'),
      onError: (error) => print('STT Error: $error'),
    );
  }

  Future<void> startListening(Function(String) onResult) async {
    bool available = await initSpeech();
    if (available) {
      _isListening = true;
      _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
        localeId: "tr_TR",
      );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
