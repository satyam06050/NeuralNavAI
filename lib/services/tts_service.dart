import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../app_res.dart';

class TtsService extends GetxService {
  final FlutterTts _flutterTts = FlutterTts();

  final isSpeaking = false.obs;
  final speechQueue = <String>[].obs;

  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage(AppRes.ttsLanguage);
      await _flutterTts.setSpeechRate(AppRes.ttsSpeedDefault);
      await _flutterTts.setVolume(AppRes.ttsVolumeDefault);

      // Listen to completion
      _flutterTts.setCompletionHandler(() {
        isSpeaking.value = false;
        _speakNext();
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  /// Add message to speech queue
  void speak(String message, {bool immediate = false}) {
    if (immediate) {
      speechQueue.clear();
      speechQueue.add(message);
    } else {
      speechQueue.add(message);
    }
    _speakNext();
  }

  /// Speak next message in queue
  Future<void> _speakNext() async {
    if (speechQueue.isEmpty || isSpeaking.value || !_isInitialized) return;

    final message = speechQueue.removeAt(0);
    await _speakMessage(message);
  }

  /// Actually speak a message
  Future<void> _speakMessage(String message) async {
    if (!_isInitialized) return;

    isSpeaking.value = true;
    try {
      await _flutterTts.speak(message);
    } catch (e) {
      print('TTS speak error: $e');
      isSpeaking.value = false;
      _speakNext();
    }
  }

  /// Stop speaking and clear queue
  Future<void> stop() async {
    await _flutterTts.stop();
    speechQueue.clear();
    isSpeaking.value = false;
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
