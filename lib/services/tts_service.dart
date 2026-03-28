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
    if (_isInitialized) {
      print('[TtsService] Already initialized');
      return;
    }

    try {
      print('[TtsService] Initializing TTS...');
      await _flutterTts.setLanguage(AppRes.ttsLanguage);
      print('[TtsService] Language set to: ${AppRes.ttsLanguage}');

      await _flutterTts.setSpeechRate(AppRes.ttsSpeedDefault);
      print('[TtsService] Speech rate set to: ${AppRes.ttsSpeedDefault}');

      await _flutterTts.setVolume(AppRes.ttsVolumeDefault);
      print('[TtsService] Volume set to: ${AppRes.ttsVolumeDefault}');

      // Listen to completion
      _flutterTts.setCompletionHandler(() {
        print('[TtsService] Speech completion callback triggered');
        isSpeaking.value = false;
        _speakNext();
      });

      _isInitialized = true;
      print('[TtsService] ✅ TTS initialization complete');
    } catch (e) {
      print('[TtsService] ❌ TTS initialization error: $e');
      // TTS initialization error handled silently
    }
  }

  /// Add message to speech queue
  void speak(String message, {bool immediate = false}) {
    print(
      '[TtsService] speak() called with message: "$message", immediate: $immediate',
    );
    print(
      '[TtsService] Initialized: $_isInitialized, Queue length: ${speechQueue.length}',
    );

    // Ensure initialization
    if (!_isInitialized) {
      print('[TtsService] Not initialized yet, attempting direct speak...');
      _speakDirect(message);
      return;
    }

    if (immediate) {
      print('[TtsService] Clearing queue for immediate speech');
      speechQueue.clear();
      speechQueue.add(message);
    } else {
      speechQueue.add(message);
    }
    _speakNext();
  }

  /// Direct speak without queue (fallback)
  Future<void> _speakDirect(String message) async {
    try {
      print('[TtsService] Direct speaking: $message');
      await _flutterTts.setLanguage(AppRes.ttsLanguage);
      await _flutterTts.setSpeechRate(AppRes.ttsSpeedDefault);
      await _flutterTts.setVolume(AppRes.ttsVolumeDefault);
      final result = await _flutterTts.speak(message);
      print('[TtsService] Direct speak completed, result: $result');
    } catch (e) {
      print('[TtsService] Direct speak error: $e');
    }
  }

  /// Speak next message in queue
  Future<void> _speakNext() async {
    if (speechQueue.isEmpty || isSpeaking.value || !_isInitialized) return;

    final message = speechQueue.removeAt(0);
    await _speakMessage(message);
  }

  /// Actually speak a message
  Future<void> _speakMessage(String message) async {
    if (!_isInitialized) {
      print('[TtsService] ERROR: Not initialized, cannot speak: $message');
      return;
    }

    print('[TtsService] Speaking message: $message');
    isSpeaking.value = true;
    try {
      await _flutterTts.speak(message);
      print('[TtsService] Message sent to FlutterTTS successfully');
    } catch (e) {
      print('[TtsService] ERROR during speak: $e');
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
