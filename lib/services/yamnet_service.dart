import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service YAMNet pour la détection d'aboiements via TensorFlow Lite
/// Classes pertinentes dans YAMNet :
/// - 69: Dog
/// - 70: Bark  
/// - 72: Howl
/// - 74: Growling
/// - 75: Whimper (dog)
class YamnetService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  // Indices des classes de chien dans YAMNet
  static const List<int> dogClassIndices = [69, 70, 72, 74, 75];
  static const Map<int, String> dogClassNames = {
    69: 'Dog',
    70: 'Bark',
    72: 'Howl', 
    74: 'Growling',
    75: 'Whimper',
  };

  bool get isInitialized => _isInitialized;

  /// Initialise le modèle YAMNet
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Charger le modèle TFLite
      _interpreter = await Interpreter.fromAsset('assets/models/yamnet.tflite');
      
      // Charger les labels
      final labelsData = await rootBundle.loadString('assets/models/yamnet_labels.csv');
      _labels = _parseLabels(labelsData);

      _isInitialized = true;
    } catch (e) {
      print('Erreur initialisation YAMNet: $e');
      _isInitialized = false;
    }
  }

  /// Parse le fichier CSV des labels
  List<String> _parseLabels(String csvData) {
    final lines = csvData.split('\n');
    final labels = <String>[];
    
    for (int i = 1; i < lines.length; i++) { // Skip header
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Format: index,mid,display_name
      final parts = line.split(',');
      if (parts.length >= 3) {
        // Le display_name peut contenir des virgules, donc on prend tout après le 2ème élément
        final displayName = parts.sublist(2).join(',').replaceAll('"', '');
        labels.add(displayName);
      }
    }
    
    return labels;
  }

  /// Analyse un fichier audio et retourne les scores de détection
  Future<YamnetResult> analyzeAudio(String audioPath) async {
    if (!_isInitialized || _interpreter == null) {
      return YamnetResult.empty();
    }

    try {
      // Lire et préparer les données audio
      final audioData = await _prepareAudioData(audioPath);
      
      if (audioData == null) {
        return YamnetResult.empty();
      }

      // Préparer l'input (YAMNet attend des échantillons audio de 0.975s à 16kHz)
      final input = audioData.reshape([1, audioData.length]);
      
      // Préparer l'output (521 classes)
      final output = List.filled(521, 0.0).reshape([1, 521]);

      // Exécuter l'inférence
      _interpreter!.run(input, output);

      // Extraire les résultats
      final scores = (output[0] as List).cast<double>();
      
      return _processResults(scores);
    } catch (e) {
      print('Erreur analyse YAMNet: $e');
      return YamnetResult.empty();
    }
  }

  /// Prépare les données audio pour YAMNet (16kHz, mono, float32)
  Future<Float32List?> _prepareAudioData(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      
      // Conversion simplifiée - dans une version production, 
      // on utiliserait un package audio pour décoder correctement
      // Pour l'instant, on simule des données audio normalisées
      
      // YAMNet attend 15600 échantillons (0.975s à 16kHz)
      const sampleCount = 15600;
      final audioData = Float32List(sampleCount);
      
      // Convertir les bytes en float32 normalisés [-1, 1]
      final dataLength = bytes.length < sampleCount * 2 ? bytes.length : sampleCount * 2;
      for (int i = 0; i < dataLength ~/ 2 && i < sampleCount; i++) {
        // Lire comme int16 little-endian et normaliser
        final sample = (bytes[i * 2] | (bytes[i * 2 + 1] << 8));
        final signedSample = sample > 32767 ? sample - 65536 : sample;
        audioData[i] = signedSample / 32768.0;
      }
      
      return audioData;
    } catch (e) {
      print('Erreur préparation audio: $e');
      return null;
    }
  }

  /// Traite les résultats de YAMNet
  YamnetResult _processResults(List<double> scores) {
    // Calculer le score total pour les classes de chien
    double dogScore = 0.0;
    int bestDogClass = -1;
    double bestDogScore = 0.0;

    for (final index in dogClassIndices) {
      if (index < scores.length) {
        final score = scores[index];
        dogScore += score;
        
        if (score > bestDogScore) {
          bestDogScore = score;
          bestDogClass = index;
        }
      }
    }

    // Trouver la classe globale avec le meilleur score
    int topClassIndex = 0;
    double topScore = 0.0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > topScore) {
        topScore = scores[i];
        topClassIndex = i;
      }
    }

    final topClassName = topClassIndex < _labels.length 
        ? _labels[topClassIndex] 
        : 'Unknown';

    // Déterminer si c'est un aboiement
    final isDogSound = dogScore > 0.3 || dogClassIndices.contains(topClassIndex);
    
    // Type de son de chien détecté
    String dogSoundType = 'unknown';
    if (bestDogClass >= 0) {
      dogSoundType = dogClassNames[bestDogClass] ?? 'unknown';
    }

    return YamnetResult(
      isDogSound: isDogSound,
      dogConfidence: dogScore.clamp(0.0, 1.0),
      dogSoundType: dogSoundType,
      topClass: topClassName,
      topClassConfidence: topScore,
      allDogScores: {
        for (final index in dogClassIndices)
          if (index < scores.length)
            dogClassNames[index] ?? 'Class $index': scores[index],
      },
    );
  }

  /// Analyse rapide pour vérifier si c'est un son de chien
  Future<bool> isDogSound(String audioPath) async {
    final result = await analyzeAudio(audioPath);
    return result.isDogSound;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

/// Résultat de l'analyse YAMNet
class YamnetResult {
  final bool isDogSound;
  final double dogConfidence;
  final String dogSoundType; // bark, howl, growl, whimper
  final String topClass;
  final double topClassConfidence;
  final Map<String, double> allDogScores;

  YamnetResult({
    required this.isDogSound,
    required this.dogConfidence,
    required this.dogSoundType,
    required this.topClass,
    required this.topClassConfidence,
    required this.allDogScores,
  });

  factory YamnetResult.empty() => YamnetResult(
    isDogSound: false,
    dogConfidence: 0.0,
    dogSoundType: 'unknown',
    topClass: 'Unknown',
    topClassConfidence: 0.0,
    allDogScores: {},
  );

  @override
  String toString() {
    return 'YamnetResult(isDog: $isDogSound, confidence: ${(dogConfidence * 100).toStringAsFixed(1)}%, type: $dogSoundType, top: $topClass)';
  }
}
