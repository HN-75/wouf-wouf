import 'package:flutter_tts/flutter_tts.dart';

/// Service Text-to-Speech pour lire les traductions en français
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialise le TTS avec la voix française
  Future<void> init() async {
    if (_isInitialized) return;

    // Configuration pour le français
    await _flutterTts.setLanguage('fr-FR');
    
    // Vitesse légèrement plus rapide pour un effet plus naturel/mignon
    await _flutterTts.setSpeechRate(0.5);
    
    // Pitch légèrement plus haut pour un effet "chien mignon"
    await _flutterTts.setPitch(1.2);
    
    // Volume max
    await _flutterTts.setVolume(1.0);

    _isInitialized = true;
  }

  /// Lit une phrase à voix haute
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await _flutterTts.speak(text);
  }

  /// Arrête la lecture en cours
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Vérifie si une voix française est disponible
  Future<bool> isFrenchAvailable() async {
    final languages = await _flutterTts.getLanguages;
    return languages.toString().toLowerCase().contains('fr');
  }

  /// Liste les voix disponibles
  Future<List<dynamic>> getAvailableVoices() async {
    return await _flutterTts.getVoices;
  }

  /// Change le pitch (1.0 = normal, >1.0 = plus aigu)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  /// Change la vitesse (0.5 = lent, 1.0 = normal, 2.0 = rapide)
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  void dispose() {
    _flutterTts.stop();
  }
}
