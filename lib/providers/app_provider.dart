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
/// CORRIGÉ : Meilleure gestion d'erreurs et callback arrêt automatique
class AppProvider extends ChangeNotifier {
  // Services
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  final BarkClassifierService _classifier = BarkClassifierService();
  final BluetoothService _bluetooth = BluetoothService();
  final PhraseGenerator _phraseGenerator = PhraseGenerator();
  final StorageService _storage = StorageService();
  final TtsService _tts = TtsService();

  // État
  UserProfile _profile = UserProfile();
  AppState _state = AppState.idle;
  String? _currentPhrase;
  BarkEmotion? _currentEmotion;
  double _confidence = 0.0;
  double _audioLevel = 0.0;
  bool _isListening = false;
  String? _errorMessage;
  String? _warningMessage;
  List<TranslationEntry> _history = [];
  bool _isFrenchTtsAvailable = true;

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
  bool get isBluetoothConnected => _bluetooth.isConnected;
  String? get bluetoothDeviceName => _bluetooth.connectedDeviceName;
  bool get isFrenchTtsAvailable => _isFrenchTtsAvailable;

  // Services exposés
  AudioRecorderService get audioRecorder => _audioRecorder;
  BluetoothService get bluetooth => _bluetooth;
  BarkClassifierService get classifier => _classifier;
  TtsService get tts => _tts;

  /// Vérifie si l'onboarding a été fait
  bool get needsOnboarding => !_profile.onboardingComplete;

  /// Initialise l'application
  Future<void> init() async {
    _state = AppState.loading;
    notifyListeners();

    try {
      await _storage.init();
      await _classifier.init();
      
      // Configurer le callback TTS pour les warnings
      _tts.onWarning = (message) {
        _warningMessage = message;
        _isFrenchTtsAvailable = false;
        notifyListeners();
      };
      await _tts.init();
      _isFrenchTtsAvailable = _tts.isFrenchAvailable;

      // Charger le profil
      final savedProfile = await _storage.loadProfile();
      if (savedProfile != null) {
        _profile = savedProfile;
      }

      // Charger l'historique
      _history = await _storage.getHistory();

      // Écouter les niveaux audio
      _audioRecorder.amplitudeStream.listen((level) {
        _audioLevel = level;
        notifyListeners();
      });

      // Callback pour arrêt automatique après 5 secondes
      _audioRecorder.onMaxDurationReached = () {
        if (_isListening) {
          _handleAutoStop();
        }
      };

      _state = AppState.idle;
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Erreur d\'initialisation: $e';
      print('Erreur init: $e');
    }

    notifyListeners();
  }

  /// Gère l'arrêt automatique après durée max
  Future<void> _handleAutoStop() async {
    _state = AppState.analyzing;
    _isListening = false;
    notifyListeners();

    // L'enregistrement est déjà arrêté par le timer
    // Récupérer le dernier fichier enregistré
    try {
      final recordings = await _audioRecorder.listRecordings();
      if (recordings.isNotEmpty) {
        // Trier par nom (contient timestamp)
        recordings.sort();
        final lastRecording = recordings.last;
        await _analyzeAndTranslate(lastRecording);
      } else {
        _state = AppState.idle;
        _errorMessage = 'Aucun enregistrement trouvé';
      }
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Erreur après arrêt auto: $e';
    }
    
    notifyListeners();
  }

  /// Met à jour le profil utilisateur
  Future<void> updateProfile({String? dogName, UserGender? gender}) async {
    // Validation du nom du chien (max 20 caractères)
    String? validatedDogName = dogName;
    if (dogName != null && dogName.length > 20) {
      validatedDogName = dogName.substring(0, 20);
    }
    
    _profile = _profile.copyWith(
      dogName: validatedDogName,
      gender: gender,
      onboardingComplete: true,
    );
    await _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Démarre l'écoute des aboiements
  Future<void> startListening() async {
    if (_isListening) return;

    // Effacer les messages précédents
    _errorMessage = null;
    _warningMessage = null;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _errorMessage = 'Permission micro refusée. Activez le micro dans les paramètres.';
      notifyListeners();
      return;
    }

    _isListening = true;
    _state = AppState.listening;
    _currentPhrase = null;
    _currentEmotion = null;
    notifyListeners();

    try {
      await _audioRecorder.startRecording();
    } catch (e) {
      _isListening = false;
      _state = AppState.error;
      _errorMessage = 'Erreur démarrage micro: $e';
      notifyListeners();
    }
  }

  /// Arrête l'écoute et analyse l'aboiement
  Future<void> stopListening() async {
    if (!_isListening) return;

    _state = AppState.analyzing;
    notifyListeners();

    try {
      final audioPath = await _audioRecorder.stopRecording();
      _isListening = false;

      if (audioPath != null) {
        await _analyzeAndTranslate(audioPath);
      } else {
        _state = AppState.idle;
        _errorMessage = 'Erreur d\'enregistrement - fichier non créé';
      }
    } catch (e) {
      _isListening = false;
      _state = AppState.error;
      _errorMessage = 'Erreur arrêt enregistrement: $e';
    }

    notifyListeners();
  }

  /// Analyse l'audio et génère la traduction
  Future<void> _analyzeAndTranslate(String audioPath) async {
    try {
      // Classifier l'aboiement
      final result = await _classifier.classify(audioPath);
      
      _currentEmotion = result.emotion;
      _confidence = result.confidence;

      // Vérifier si c'est un son de chien
      if (!result.isDogSound && result.emotion == BarkEmotion.inconnu) {
        _currentPhrase = "Je n'ai pas détecté d'aboiement. Réessayez quand votre chien aboie !";
        _state = AppState.result;
        await _tts.speak(_currentPhrase!);
        notifyListeners();
        return;
      }

      // Générer la phrase
      _currentPhrase = _phraseGenerator.generate(
        result.emotion,
        _profile.gender,
      );

      // Sauvegarder dans l'historique
      final entry = TranslationEntry(
        timestamp: DateTime.now(),
        emotion: result.emotion.label,
        phrase: _currentPhrase!,
        confidence: _confidence,
        audioPath: audioPath,
      );
      await _storage.addToHistory(entry);
      _history.insert(0, entry);

      // Limiter l'historique à 100 entrées
      if (_history.length > 100) {
        _history = _history.sublist(0, 100);
      }

      _state = AppState.result;

      // Lire la phrase
      await _tts.speak(_currentPhrase!);
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Erreur d\'analyse: $e';
      print('Erreur analyse: $e');
    }

    notifyListeners();
  }

  /// Rejoue la dernière phrase
  Future<void> replayPhrase() async {
    if (_currentPhrase != null) {
      try {
        await _tts.speak(_currentPhrase!);
      } catch (e) {
        _errorMessage = 'Erreur lecture vocale';
        notifyListeners();
      }
    }
  }

  /// Ajoute un échantillon d'apprentissage
  Future<void> addTrainingSample(String audioPath, BarkEmotion emotion) async {
    try {
      await _classifier.addTrainingSample(audioPath, emotion);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur ajout échantillon: $e';
      notifyListeners();
    }
  }

  /// Réinitialise l'état pour une nouvelle traduction
  void reset() {
    _state = AppState.idle;
    _currentPhrase = null;
    _currentEmotion = null;
    _confidence = 0.0;
    _errorMessage = null;
    _warningMessage = null;
    notifyListeners();
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Efface le message de warning
  void clearWarning() {
    _warningMessage = null;
    notifyListeners();
  }

  /// Efface l'historique
  Future<void> clearHistory() async {
    await _storage.clearHistory();
    _history.clear();
    notifyListeners();
  }

  /// Retourne les stats d'apprentissage
  Map<BarkEmotion, int> getTrainingStats() {
    return _classifier.getTrainingStats();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _bluetooth.dispose();
    _classifier.dispose();
    _tts.dispose();
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

extension AppStateExtension on AppState {
  String get label {
    switch (this) {
      case AppState.loading:
        return 'Chargement...';
      case AppState.idle:
        return 'Prêt';
      case AppState.listening:
        return 'J\'écoute... (5s max)';
      case AppState.analyzing:
        return 'Analyse en cours...';
      case AppState.result:
        return 'Traduction';
      case AppState.error:
        return 'Erreur';
    }
  }
}
