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
  List<TranslationEntry> _history = [];

  // Getters
  UserProfile get profile => _profile;
  AppState get state => _state;
  String? get currentPhrase => _currentPhrase;
  BarkEmotion? get currentEmotion => _currentEmotion;
  double get confidence => _confidence;
  double get audioLevel => _audioLevel;
  bool get isListening => _isListening;
  String? get errorMessage => _errorMessage;
  List<TranslationEntry> get history => _history;
  bool get isBluetoothConnected => _bluetooth.isConnected;
  String? get bluetoothDeviceName => _bluetooth.connectedDeviceName;

  // Services exposés
  AudioRecorderService get audioRecorder => _audioRecorder;
  BluetoothService get bluetooth => _bluetooth;
  BarkClassifierService get classifier => _classifier;

  /// Vérifie si l'onboarding a été fait
  bool get needsOnboarding => !_profile.onboardingComplete;

  /// Initialise l'application
  Future<void> init() async {
    _state = AppState.loading;
    notifyListeners();

    try {
      await _storage.init();
      await _classifier.init();
      await _tts.init();

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

      _state = AppState.idle;
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Erreur d\'initialisation: $e';
    }

    notifyListeners();
  }

  /// Met à jour le profil utilisateur
  Future<void> updateProfile({String? dogName, UserGender? gender}) async {
    _profile = _profile.copyWith(
      dogName: dogName,
      gender: gender,
      onboardingComplete: true,
    );
    await _storage.saveProfile(_profile);
    notifyListeners();
  }

  /// Démarre l'écoute des aboiements
  Future<void> startListening() async {
    if (_isListening) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _errorMessage = 'Permission micro refusée';
      notifyListeners();
      return;
    }

    _isListening = true;
    _state = AppState.listening;
    _currentPhrase = null;
    _currentEmotion = null;
    notifyListeners();

    await _audioRecorder.startRecording();
  }

  /// Arrête l'écoute et analyse l'aboiement
  Future<void> stopListening() async {
    if (!_isListening) return;

    _state = AppState.analyzing;
    notifyListeners();

    final audioPath = await _audioRecorder.stopRecording();
    _isListening = false;

    if (audioPath != null) {
      await _analyzeAndTranslate(audioPath);
    } else {
      _state = AppState.idle;
      _errorMessage = 'Erreur d\'enregistrement';
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

      _state = AppState.result;

      // Lire la phrase
      await _tts.speak(_currentPhrase!);
    } catch (e) {
      _state = AppState.error;
      _errorMessage = 'Erreur d\'analyse: $e';
    }

    notifyListeners();
  }

  /// Rejoue la dernière phrase
  Future<void> replayPhrase() async {
    if (_currentPhrase != null) {
      await _tts.speak(_currentPhrase!);
    }
  }

  /// Ajoute un échantillon d'apprentissage
  Future<void> addTrainingSample(String audioPath, BarkEmotion emotion) async {
    await _classifier.addTrainingSample(audioPath, emotion);
    notifyListeners();
  }

  /// Réinitialise l'état pour une nouvelle traduction
  void reset() {
    _state = AppState.idle;
    _currentPhrase = null;
    _currentEmotion = null;
    _confidence = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  /// Efface l'historique
  Future<void> clearHistory() async {
    await _storage.clearHistory();
    _history.clear();
    notifyListeners();
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
        return 'J\'écoute...';
      case AppState.analyzing:
        return 'Analyse en cours...';
      case AppState.result:
        return 'Traduction';
      case AppState.error:
        return 'Erreur';
    }
  }
}
