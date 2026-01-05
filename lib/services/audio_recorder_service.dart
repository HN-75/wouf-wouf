import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service d'enregistrement audio pour capturer les aboiements
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;
  
  // Stream pour la détection de niveau sonore
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  bool get isRecording => _isRecording;

  /// Vérifie si le micro est disponible
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Démarre l'enregistrement
  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${directory.path}/bark_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
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

    return _currentPath;
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    await _amplitudeSubscription?.cancel();
    final path = await _recorder.stop();
    _isRecording = false;

    return path;
  }

  /// Enregistre pendant une durée spécifique (pour la détection automatique)
  Future<String?> recordForDuration(Duration duration) async {
    final path = await startRecording();
    if (path == null) return null;

    await Future.delayed(duration);
    return await stopRecording();
  }

  /// Supprime un fichier audio
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Liste tous les enregistrements sauvegardés
  Future<List<String>> listRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final files = await dir.list().toList();
    
    return files
        .whereType<File>()
        .where((f) => f.path.contains('bark_') && f.path.endsWith('.m4a'))
        .map((f) => f.path)
        .toList();
  }

  void dispose() {
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
    _recorder.dispose();
  }
}
