import 'package:flutter_tts/flutter_tts.dart';

/// Service Text-to-Speech pour lire les traductions en français
/// CORRIGÉ : Ajout vérification voix française et fallback
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isFrenchAvailable = false;
  String _currentLanguage = 'fr-FR';

  /// Callback pour notifier l'UI si la voix française n'est pas disponible
  Function(String message)? onWarning;

  /// Initialise le TTS avec la voix française
  Future<void> init() async {
    if (_isInitialized) return;

    // Vérifier si le français est disponible
    _isFrenchAvailable = await _checkFrenchAvailable();
    
    if (_isFrenchAvailable) {
      _currentLanguage = 'fr-FR';
      await _flutterTts.setLanguage('fr-FR');
    } else {
      // Fallback : essayer fr, puis en-US
      final languages = await _flutterTts.getLanguages;
      final langList = languages is List ? languages.cast<String>() : <String>[];
      
      if (langList.any((l) => l.toLowerCase().startsWith('fr'))) {
        _currentLanguage = langList.firstWhere((l) => l.toLowerCase().startsWith('fr'));
        await _flutterTts.setLanguage(_currentLanguage);
        _isFrenchAvailable = true;
      } else {
        // Pas de français du tout - utiliser anglais
        _currentLanguage = 'en-US';
        await _flutterTts.setLanguage('en-US');
        onWarning?.call('Voix française non disponible. Installez une voix française dans les paramètres de votre téléphone.');
      }
    }
    
    // Vitesse légèrement plus rapide pour un effet plus naturel/mignon
    await _flutterTts.setSpeechRate(0.5);
    
    // Pitch légèrement plus haut pour un effet "chien mignon"
    await _flutterTts.setPitch(1.2);
    
    // Volume max
    await _flutterTts.setVolume(1.0);

    _isInitialized = true;
  }

  /// Vérifie si une voix française est disponible
  Future<bool> _checkFrenchAvailable() async {
    try {
      final languages = await _flutterTts.getLanguages;
      if (languages == null) return false;
      
      final langList = languages is List ? languages : [];
      return langList.any((l) => 
        l.toString().toLowerCase().contains('fr-fr') ||
        l.toString().toLowerCase() == 'fr'
      );
    } catch (e) {
      print('Erreur vérification langues TTS: $e');
      return false;
    }
  }

  /// Retourne true si la voix française est disponible
  bool get isFrenchAvailable => _isFrenchAvailable;
  
  /// Retourne la langue actuellement utilisée
  String get currentLanguage => _currentLanguage;

  /// Lit une phrase à voix haute
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Erreur TTS speak: $e');
      onWarning?.call('Erreur de lecture vocale');
    }
  }

  /// Arrête la lecture en cours
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Erreur TTS stop: $e');
    }
  }

  /// Vérifie si une voix française est disponible (méthode publique)
  Future<bool> checkFrenchAvailable() async {
    return await _checkFrenchAvailable();
  }

  /// Liste les voix disponibles
  Future<List<dynamic>> getAvailableVoices() async {
    try {
      return await _flutterTts.getVoices ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Liste les langues disponibles
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      if (languages == null) return [];
      return languages is List ? languages.cast<String>() : [];
    } catch (e) {
      return [];
    }
  }

  /// Change le pitch (1.0 = normal, >1.0 = plus aigu)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Change la vitesse (0.5 = lent, 1.0 = normal, 2.0 = rapide)
  Future<void> setRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.25, 2.0));
  }

  void dispose() {
    _flutterTts.stop();
  }
}
