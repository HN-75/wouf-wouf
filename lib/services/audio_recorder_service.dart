import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service d'enregistrement audio pour capturer les aboiements
/// CORRIGÉ : Enregistre en WAV PCM 16kHz mono pour compatibilité YAMNet
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;
  Timer? _maxDurationTimer;
  
  // Durée maximale d'enregistrement (5 secondes)
  static const Duration maxRecordingDuration = Duration(seconds: 5);
  
  // Stream pour la détection de niveau sonore
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  
  // Callback pour arrêt automatique
  Function()? onMaxDurationReached;
  
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  bool get isRecording => _isRecording;

  /// Vérifie si le micro est disponible
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Démarre l'enregistrement en WAV PCM 16kHz mono
  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${directory.path}/bark_$timestamp.wav';

    try {
      await _recorder.start(
        const RecordConfig(
          // CORRECTION : WAV PCM 16-bit au lieu de AAC
          encoder: AudioEncoder.wav,
          // CORRECTION : 16kHz pour YAMNet (au lieu de 44.1kHz)
          sampleRate: 16000,
          // Mono pour réduire la taille et compatibilité ML
          numChannels: 1,
          // Bitrate non utilisé pour WAV mais requis
          bitRate: 256000,
        ),
        path: _currentPath!,
      );

      _isRecording = true;

      // Écouter l'amplitude pour la visualisation
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        // Normaliser l'amplitude entre 0 et 1
        final normalized = (amp.current + 60) / 60; // -60dB à 0dB -> 0 à 1
        _amplitudeController.add(normalized.clamp(0.0, 1.0));
      });

      // Timer pour arrêt automatique après 5 secondes
      _maxDurationTimer = Timer(maxRecordingDuration, () async {
        if (_isRecording) {
          await stopRecording();
          onMaxDurationReached?.call();
        }
      });

      return _currentPath;
    } catch (e) {
      print('Erreur démarrage enregistrement: $e');
      return null;
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('Erreur arrêt enregistrement: $e');
      _isRecording = false;
      return _currentPath;
    }
  }

  /// Enregistre pendant une durée spécifique (pour la détection automatique)
  Future<String?> recordForDuration(Duration duration) async {
    // Limiter à la durée max
    final actualDuration = duration > maxRecordingDuration 
        ? maxRecordingDuration 
        : duration;
    
    final path = await startRecording();
    if (path == null) return null;

    await Future.delayed(actualDuration);
    return await stopRecording();
  }

  /// Supprime un fichier audio
  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erreur suppression fichier: $e');
    }
  }

  /// Liste tous les enregistrements sauvegardés
  Future<List<String>> listRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = await dir.list().toList();
      
      return files
          .whereType<File>()
          .where((f) => f.path.contains('bark_') && 
                       (f.path.endsWith('.wav') || f.path.endsWith('.m4a')))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      print('Erreur liste enregistrements: $e');
      return [];
    }
  }

  /// Nettoie les anciens enregistrements (garde les 20 derniers)
  Future<void> cleanOldRecordings() async {
    try {
      final recordings = await listRecordings();
      if (recordings.length > 20) {
        // Trier par date (timestamp dans le nom)
        recordings.sort();
        // Supprimer les plus anciens
        for (int i = 0; i < recordings.length - 20; i++) {
          await deleteRecording(recordings[i]);
        }
      }
    } catch (e) {
      print('Erreur nettoyage: $e');
    }
  }

  void dispose() {
    _maxDurationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
  }
}
