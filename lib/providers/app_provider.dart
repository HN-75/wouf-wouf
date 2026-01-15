import 'package:flutter/foundation.dart';
import '../models/bark_emotion.dart';
import '../models/user_profile.dart';
import '../services/audio_recorder_service.dart';
import '../services/bark_classifier_service.dart';
import '../services/bluetooth_service.dart';
import '../services/phrase_generator.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

/// Provider principal gérant l'état de l'application
/// V5 : Lazy loading du ML pour éviter les crashes au démarrage
class AppProvider extends ChangeNotifier {
  // Services (initialisés de manière lazy)
  AudioRecorderService? _audioRecorder;
  BarkClassifierService? _classifier;
  BluetoothService? _bluetooth;
  PhraseGenerator? _phraseGenerator;
  StorageService? _storage;
  TtsService? _tts;

  // État
  UserProfile _profile = UserProfile();
  AppState _state = AppState.loading;
  String? _currentPhrase;
  BarkEmotion? _currentEmotion;
  double _confidence = 0.0;
  double _audioLevel = 0.0;
  bool _isListening = false;
  String? _errorMessage;
  String? _warningMessage;
  List<TranslationEntry> _history = [];
  bool _isFrenchTtsAvailable = true;
  bool _servicesReady = false;
  bool _mlLoaded = false;
  bool _mlFailed = false;

  // Getters
  UserProfile get profile => _profile;
  AppState get state => _state;
  String? get currentPhrase => _currentPhrase;
  BarkEmotion? get currentEmotion => _currentEmotion;
  double get confidence => _confidence;
  double get audioLevel => _audioLevel;
  bool get isListening => _isListening;
  String? get errorMessage => _errorMessage;
  String? get warningMessage => _warningMessage;
  List<TranslationEntry> get history => _history;
  bool get isBluetoothConnected => _bluetooth?.isConnected ?? false;
  String? get bluetoothDeviceName => _bluetooth?.connectedDeviceName;
  bool get isFrenchTtsAvailable => _isFrenchTtsAvailable;
  bool get servicesReady => _servicesReady;
  bool get mlLoaded => _mlLoaded;

  // Services exposés (avec null safety)
  AudioRecorderService? get audioRecorder => _audioRecorder;
  BluetoothService? get bluetooth => _bluetooth;
  BarkClassifierService? get classifier => _classifier;
  TtsService? get tts => _tts;

  /// Vérifie si l'onboarding a été fait
  bool get needsOnboarding => !_profile.onboardingComplete;

  /// Initialise l'application (services légers uniquement, pas de ML)
  Future<void> init() async {
    _state = AppState.loading;
    notifyListeners();

    try {
      await _initLightServices();
      _state = AppState.idle;
      _servicesReady = true;
    } catch (e) {
      debugPrint('Erreur init (non bloquante): $e');
      _state = AppState.idle;
      _warningMessage = 'Certaines fonctionnalités peuvent être limitées';
    }

    notifyListeners();
  }

  /// Initialise les services légers (sans ML)
  Future<void> _initLightServices() async {
    // Storage
    try {
      _storage = StorageService();
      await _storage!.init();
      
      final savedProfile = await _storage!.loadProfile();
      if (savedProfile != null) {
        _profile = savedProfile;
      }
      _history = await _storage!.getHistory();
    } catch (e) {
      debugPrint('Erreur storage: $e');
      _storage = null;
    }

    // Phrase generator (simple)
    try {
      _phraseGenerator = PhraseGenerator();
    } catch (e) {
      debugPrint('Erreur phrase generator: $e');
    }

    // TTS
    try {
      _tts = TtsService();
      _tts!.onWarning = (message) {
        _warningMessage = message;
        _isFrenchTtsAvailable = false;
        notifyListeners();
      };
      await _tts!.init();
      _isFrenchTtsAvailable = _tts!.isFrenchAvailable;
    } catch (e) {
      debugPrint('Erreur TTS: $e');
      _tts = null;
      _isFrenchTtsAvailable = false;
    }

    // Audio recorder
    try {
      _audioRecorder = AudioRecorderService();
      
      _audioRecorder!.amplitudeStream.listen((level) {
        _audioLevel = level;
        notifyListeners();
      });

      _audioRecorder!.onMaxDurationReached = () {
        if (_isListening) {
          _handleAutoStop();
        }
      };
    } catch (e) {
      debugPrint('Erreur audio recorder: $e');
      _audioRecorder = null;
    }

    // Bluetooth (optionnel)
    try {
      _bluetooth = BluetoothService();
    } catch (e) {
      debugPrint('Erreur bluetooth: $e');
      _bluetooth = null;
    }
  }

  /// Charge le ML en lazy (appelé au premier clic sur Écouter)
  Future<bool> _ensureMLLoaded() async {
    if (_mlLoaded) return true;
    if (_mlFailed) return false;

    try {
      _classifier = BarkClassifierService();
      await _classifier!.init();
      _mlLoaded = true;
      debugPrint('ML chargé avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur chargement ML: $e');
      _mlFailed = true;
      _classifier = null;
      _warningMessage = 'Mode basique activé (ML non disponible)';
      notifyListeners();
      return false;
    }
  }

  /// Gère l'arrêt automatique après durée max
  Future<void> _handleAutoStop() async {
    _state = AppState.analyzing;
    _isListening = false;
    notifyListeners();

    try {
      if (_audioRecorder == null) {
        _state = AppState.idle;
        _errorMessage = 'Enregistreur non disponible';
        notifyListeners();
        return;
      }

      final recordings = await _audioRecorder!.listRecordings();
      if (recordings.isEmpty) {
        _state = AppState.idle;
        _errorMessage = 'Aucun enregistrement trouvé';
        notifyListeners();
        return;
      }

      final lastRecording = recordings.last;
      await _analyzeAndTranslate(lastRecording);
    } catch (e) {
      debugPrint('Erreur auto-stop: $e');
      _state = AppState.idle;
      _errorMessage = 'Erreur lors de l\'analyse';
      notifyListeners();
    }
  }

  /// Démarre l'écoute
  Future<void> startListening() async {
    if (_audioRecorder == null) {
      _errorMessage = 'Micro non disponible sur cet appareil';
      notifyListeners();
      return;
    }

    // Charger le ML en lazy si pas encore fait
    await _ensureMLLoaded();

    final hasPermission = await _audioRecorder!.hasPermission();
    if (!hasPermission) {
      _errorMessage = 'Permission micro requise';
      notifyListeners();
      return;
    }

    _state = AppState.listening;
    _isListening = true;
    _currentPhrase = null;
    _currentEmotion = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await _audioRecorder!.startRecording();
    } catch (e) {
      debugPrint('Erreur démarrage enregistrement: $e');
      _state = AppState.idle;
      _isListening = false;
      _errorMessage = 'Impossible de démarrer l\'enregistrement';
      notifyListeners();
    }
  }

  /// Arrête l'écoute et analyse
  Future<void> stopListening() async {
    if (!_isListening || _audioRecorder == null) return;

    _state = AppState.analyzing;
    _isListening = false;
    notifyListeners();

    try {
      final path = await _audioRecorder!.stopRecording();
      if (path != null) {
        await _analyzeAndTranslate(path);
      } else {
        _state = AppState.idle;
        _errorMessage = 'Enregistrement échoué';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur arrêt enregistrement: $e');
      _state = AppState.idle;
      _errorMessage = 'Erreur lors de l\'arrêt';
      notifyListeners();
    }
  }

  /// Analyse l'audio et génère la traduction
  Future<void> _analyzeAndTranslate(String audioPath) async {
    try {
      BarkEmotion emotion;
      double conf;

      // Utiliser le classifier si disponible, sinon mode basique
      if (_classifier != null && _mlLoaded) {
        final result = await _classifier!.classify(audioPath);
        emotion = result.emotion;
        conf = result.confidence;
      } else {
        // Mode basique : analyse simple sans ML
        emotion = _simpleAnalysis();
        conf = 0.5;
      }

      _currentEmotion = emotion;
      _confidence = conf;

      // Générer la phrase
      if (_phraseGenerator != null) {
        _currentPhrase = _phraseGenerator!.generate(emotion, _profile.gender);
      } else {
        _currentPhrase = _getDefaultPhrase(emotion);
      }

      // Ajouter à l'historique
      final entry = TranslationEntry(
        emotion: emotion.label,
        phrase: _currentPhrase!,
        confidence: conf,
        timestamp: DateTime.now(),
      );
      _history.insert(0, entry);
      if (_history.length > 100) _history.removeLast();
      
      // Sauvegarder
      await _storage?.saveHistory(_history);

      _state = AppState.result;
      notifyListeners();

      // Lire la phrase
      await _tts?.speak(_currentPhrase!);
    } catch (e) {
      debugPrint('Erreur analyse: $e');
      _state = AppState.idle;
      _errorMessage = 'Erreur lors de l\'analyse audio';
      notifyListeners();
    }
  }

  /// Analyse simple sans ML (fallback)
  BarkEmotion _simpleAnalysis() {
    // Retourne une émotion basée sur des probabilités réalistes
    final emotions = [
      BarkEmotion.faim,
      BarkEmotion.jouer,
      BarkEmotion.sortir,
      BarkEmotion.joie,
      BarkEmotion.peur,
      BarkEmotion.douleur,
    ];
    final weights = [0.2, 0.25, 0.25, 0.15, 0.1, 0.05];
    
    final random = DateTime.now().millisecondsSinceEpoch % 100 / 100;
    double cumulative = 0;
    for (int i = 0; i < emotions.length; i++) {
      cumulative += weights[i];
      if (random < cumulative) {
        return emotions[i];
      }
    }
    return BarkEmotion.joie;
  }

  /// Phrase par défaut si le générateur échoue
  String _getDefaultPhrase(BarkEmotion emotion) {
    switch (emotion) {
      case BarkEmotion.faim:
        return "J'ai faim !";
      case BarkEmotion.jouer:
        return "On joue ?";
      case BarkEmotion.peur:
        return "J'ai peur...";
      case BarkEmotion.sortir:
        return "Je veux sortir !";
      case BarkEmotion.douleur:
        return "Aïe, j'ai mal...";
      case BarkEmotion.joie:
        return "Je suis content !";
      default:
        return "Wouf wouf !";
    }
  }

  /// Ajoute un échantillon d'entraînement
  Future<void> addTrainingSample(String audioPath, BarkEmotion emotion) async {
    await _ensureMLLoaded();
    if (_classifier != null) {
      await _classifier!.addTrainingSample(audioPath, emotion);
    }
  }

  /// Met à jour le profil utilisateur
  Future<void> setProfile(UserProfile profile) async {
    _profile = profile;
    await _storage?.saveProfile(profile);
    notifyListeners();
  }

  /// Alias pour setProfile (compatibilité)
  Future<void> updateProfile(UserProfile profile) async {
    await setProfile(profile);
  }

  /// Réinitialise l'état
  void reset() {
    _currentPhrase = null;
    _currentEmotion = null;
    _confidence = 0.0;
    _errorMessage = null;
    _state = AppState.idle;
    notifyListeners();
  }

  /// Rejoue la dernière phrase
  Future<void> replay() async {
    if (_currentPhrase != null) {
      await _tts?.speak(_currentPhrase!);
    }
  }

  /// Alias pour replay (compatibilité)
  Future<void> replayPhrase() async {
    await replay();
  }

  /// Efface l'historique
  Future<void> clearHistory() async {
    _history.clear();
    await _storage?.clearHistory();
    notifyListeners();
  }

  /// Libère les ressources
  @override
  void dispose() {
    _audioRecorder?.dispose();
    _tts?.dispose();
    super.dispose();
  }
}

/// États de l'application
enum AppState {
  loading,
  idle,
  listening,
  analyzing,
  result,
  error,
}
