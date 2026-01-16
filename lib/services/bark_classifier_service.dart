import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../models/bark_emotion.dart';
import 'package:path_provider/path_provider.dart';
import 'yamnet_service.dart';

/// Service de classification des aboiements
/// Utilise YAMNet pour détecter les aboiements + analyse des caractéristiques pour l'émotion
class BarkClassifierService {
  final YamnetService _yamnet = YamnetService();
  bool _isInitialized = false;
  final Random _random = Random();
  
  // Données d'apprentissage stockées localement
  final Map<BarkEmotion, List<AudioFeatures>> _trainingData = {};
  
  /// Initialise le classificateur
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Initialiser YAMNet
    await _yamnet.init();
    
    // Charger les données d'apprentissage sauvegardées
    await _loadTrainingData();
    
    // Si pas de données, utiliser le modèle de base pré-entraîné
    if (_trainingData.isEmpty) {
      _initializeBaseModel();
    }
    
    _isInitialized = true;
  }

  /// Initialise le modèle de base avec des caractéristiques typiques
  /// Basé sur les recherches scientifiques sur les vocalisations canines :
  /// - Pongrácz et al. (2005) : Classification of dog barks
  /// - Molnár et al. (2008) : Classification of dog barks by acoustic parameters
  void _initializeBaseModel() {
    // FAIM : aboiements répétitifs, fréquence moyenne (300-400Hz), durée courte, tonalité montante
    // Les chiens affamés produisent des aboiements insistants et réguliers
    _trainingData[BarkEmotion.faim] = [
      AudioFeatures(pitch: 320, duration: 0.35, intensity: 0.55, repetition: 0.80, harmonicity: 0.45),
      AudioFeatures(pitch: 350, duration: 0.30, intensity: 0.60, repetition: 0.85, harmonicity: 0.50),
      AudioFeatures(pitch: 380, duration: 0.25, intensity: 0.65, repetition: 0.80, harmonicity: 0.55),
      AudioFeatures(pitch: 340, duration: 0.32, intensity: 0.58, repetition: 0.82, harmonicity: 0.48),
    ];
    
    // JOUER : aboiements aigus (400-500Hz), courts, très répétitifs, haute énergie, tonalité variable
    // Les aboiements de jeu sont caractérisés par leur variabilité et leur énergie
    _trainingData[BarkEmotion.jouer] = [
      AudioFeatures(pitch: 420, duration: 0.25, intensity: 0.75, repetition: 0.85, harmonicity: 0.65),
      AudioFeatures(pitch: 450, duration: 0.20, intensity: 0.80, repetition: 0.90, harmonicity: 0.70),
      AudioFeatures(pitch: 480, duration: 0.15, intensity: 0.85, repetition: 0.95, harmonicity: 0.75),
      AudioFeatures(pitch: 460, duration: 0.18, intensity: 0.82, repetition: 0.92, harmonicity: 0.72),
    ];
    
    // PEUR : aboiements graves (150-250Hz), longs, gémissements, basse fréquence, tonalité descendante
    // La peur produit des sons plus graves et prolongés
    _trainingData[BarkEmotion.peur] = [
      AudioFeatures(pitch: 180, duration: 1.00, intensity: 0.35, repetition: 0.25, harmonicity: 0.25),
      AudioFeatures(pitch: 200, duration: 0.80, intensity: 0.40, repetition: 0.30, harmonicity: 0.30),
      AudioFeatures(pitch: 220, duration: 0.70, intensity: 0.45, repetition: 0.35, harmonicity: 0.35),
      AudioFeatures(pitch: 190, duration: 0.90, intensity: 0.38, repetition: 0.28, harmonicity: 0.28),
    ];
    
    // SORTIR : aboiements insistants, fréquence moyenne-haute (360-410Hz), durée moyenne
    // Demande d'attention avec une certaine urgence
    _trainingData[BarkEmotion.sortir] = [
      AudioFeatures(pitch: 360, duration: 0.45, intensity: 0.65, repetition: 0.65, harmonicity: 0.50),
      AudioFeatures(pitch: 380, duration: 0.40, intensity: 0.70, repetition: 0.70, harmonicity: 0.55),
      AudioFeatures(pitch: 400, duration: 0.35, intensity: 0.75, repetition: 0.75, harmonicity: 0.60),
      AudioFeatures(pitch: 390, duration: 0.38, intensity: 0.72, repetition: 0.72, harmonicity: 0.57),
    ];
    
    // DOULEUR : gémissements, sons aigus et plaintifs (480-530Hz), longue durée, haute harmonicité
    // Les vocalisations de douleur sont distinctives par leur tonalité plaintive
    _trainingData[BarkEmotion.douleur] = [
      AudioFeatures(pitch: 480, duration: 1.00, intensity: 0.55, repetition: 0.25, harmonicity: 0.75),
      AudioFeatures(pitch: 500, duration: 1.20, intensity: 0.50, repetition: 0.20, harmonicity: 0.80),
      AudioFeatures(pitch: 520, duration: 1.50, intensity: 0.45, repetition: 0.15, harmonicity: 0.85),
      AudioFeatures(pitch: 510, duration: 1.30, intensity: 0.48, repetition: 0.18, harmonicity: 0.82),
    ];
    
    // JOIE : aboiements courts (0.1-0.2s), aigus (400-450Hz), très énergiques, haute répétition
    // L'excitation positive produit des sons rapides et énergiques
    _trainingData[BarkEmotion.joie] = [
      AudioFeatures(pitch: 400, duration: 0.20, intensity: 0.85, repetition: 0.90, harmonicity: 0.60),
      AudioFeatures(pitch: 420, duration: 0.15, intensity: 0.90, repetition: 0.95, harmonicity: 0.65),
      AudioFeatures(pitch: 450, duration: 0.10, intensity: 0.95, repetition: 1.00, harmonicity: 0.70),
      AudioFeatures(pitch: 430, duration: 0.12, intensity: 0.92, repetition: 0.97, harmonicity: 0.67),
    ];
  }

  /// Classifie un fichier audio
  Future<ClassificationResult> classify(String audioPath) async {
    if (!_isInitialized) await init();
    
    // Étape 1 : Vérifier avec YAMNet si c'est un son de chien
    final yamnetResult = await _yamnet.analyzeAudio(audioPath);
    
    // CORRECTION : Seuil augmenté de 0.2 à 0.6 pour filtrer la voix humaine
    if (!yamnetResult.isDogSound && yamnetResult.dogConfidence < 0.6) {
      // Ce n'est probablement pas un son de chien
      print('DEBUG: Son rejeté par YAMNet - Confiance: ${yamnetResult.dogConfidence}, Type: ${yamnetResult.topClass}');
      return ClassificationResult(
        emotion: BarkEmotion.inconnu,
        confidence: 0.0,
        features: AudioFeatures.empty(),
        isDogSound: false,
        yamnetType: yamnetResult.topClass,
      );
    }
    
    // Étape 2 : Extraire les caractéristiques audio
    final features = await _extractFeatures(audioPath);
    print('DEBUG: Caractéristiques extraites - $features');
    
    // Étape 3 : Utiliser le type YAMNet pour affiner la classification
    BarkEmotion? yamnetHint = _getEmotionHintFromYamnet(yamnetResult.dogSoundType);
    print('DEBUG: Indice YAMNet - $yamnetHint (type: ${yamnetResult.dogSoundType})');
    
    // Étape 4 : Trouver l'émotion la plus proche avec KNN
    BarkEmotion bestMatch = BarkEmotion.inconnu;
    double bestScore = double.infinity;
    Map<BarkEmotion, double> allScores = {};
    
    for (final entry in _trainingData.entries) {
      double totalDistance = 0;
      for (final trainFeatures in entry.value) {
        totalDistance += features.distanceTo(trainFeatures);
      }
      final avgDistance = totalDistance / entry.value.length;
      allScores[entry.key] = avgDistance;
      
      // Bonus si YAMNet suggère cette émotion
      final adjustedDistance = yamnetHint == entry.key 
          ? avgDistance * 0.7 // 30% de bonus
          : avgDistance;
      
      if (adjustedDistance < bestScore) {
        bestScore = adjustedDistance;
        bestMatch = entry.key;
      }
    }
    
    // Calculer la confiance (inverse de la distance, normalisé)
    // Plus la distance est faible, plus la confiance est haute
    final confidence = (1.0 / (1.0 + bestScore * 0.5)).clamp(0.3, 0.95);
    
    print('DEBUG: Classification - Émotion: ${bestMatch.label}, Confiance: ${(confidence * 100).toStringAsFixed(0)}%, Distance: ${bestScore.toStringAsFixed(2)}');
    print('DEBUG: Tous les scores - $allScores');
    
    return ClassificationResult(
      emotion: bestMatch,
      confidence: confidence,
      features: features,
      isDogSound: true,
      yamnetType: yamnetResult.dogSoundType,
      yamnetConfidence: yamnetResult.dogConfidence,
    );
  }

  /// Donne un indice d'émotion basé sur le type YAMNet
  BarkEmotion? _getEmotionHintFromYamnet(String yamnetType) {
    switch (yamnetType.toLowerCase()) {
      case 'bark':
        return null; // Trop générique
      case 'howl':
        return BarkEmotion.peur; // Les hurlements sont souvent liés à l'anxiété
      case 'growling':
        return BarkEmotion.peur; // Ou agressivité, mais on reste safe
      case 'whimper':
        return BarkEmotion.douleur; // Les gémissements indiquent souvent la douleur
      default:
        return null;
    }
  }

  /// Extrait les caractéristiques audio d'un fichier
  Future<AudioFeatures> _extractFeatures(String audioPath) async {
    final file = File(audioPath);
    
    if (!await file.exists()) {
      return AudioFeatures.empty();
    }
    
    // Lire les données du fichier
    final bytes = await file.readAsBytes();
    
    // Analyse des caractéristiques
    final features = _analyzeAudioBytes(bytes);
    
    return features;
  }

  /// Analyse les bytes audio pour extraire des caractéristiques
  AudioFeatures _analyzeAudioBytes(Uint8List bytes) {
    if (bytes.length < 100) {
      return AudioFeatures.empty();
    }
    
    // Sauter l'en-tête du fichier audio (44 bytes pour WAV, variable pour M4A)
    final dataStart = min(44, bytes.length ~/ 10);
    final audioBytes = bytes.sublist(dataStart);
    
    if (audioBytes.isEmpty) {
      return AudioFeatures.empty();
    }
    
    // Calculer l'intensité moyenne (RMS)
    double sum = 0;
    double maxValue = 0;
    List<double> samples = [];
    
    for (int i = 0; i < audioBytes.length - 1; i += 2) {
      // Lire comme int16 little-endian
      int sample = audioBytes[i] | (audioBytes[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      
      final absValue = sample.abs().toDouble();
      sum += absValue * absValue;
      maxValue = max(maxValue, absValue);
      samples.add(sample.toDouble());
    }
    
    final rms = samples.isNotEmpty ? sqrt(sum / samples.length) : 0;
    final intensity = (rms / 16384).clamp(0.0, 1.0); // Normaliser
    
    // Estimer le pitch avec autocorrélation simplifiée
    final pitch = _estimatePitch(samples);
    
    // Estimer la durée en secondes (16000 Hz pour WAV YAMNet, 16-bit)
    final duration = (audioBytes.length / 2 / 16000).clamp(0.1, 5.0);
    
    // Estimer la répétition (régularité des pics)
    final repetition = _estimateRepetition(samples);
    
    // Estimer l'harmonicité (rapport signal/bruit)
    final harmonicity = _estimateHarmonicity(samples);
    
    return AudioFeatures(
      pitch: pitch.clamp(100.0, 800.0),
      duration: duration,
      intensity: intensity,
      repetition: repetition,
      harmonicity: harmonicity,
    );
  }

  /// Estime le pitch avec une méthode d'autocorrélation simplifiée
  double _estimatePitch(List<double> samples) {
    if (samples.length < 1000) {
      return 350.0; // Valeur par défaut
    }
    
    // Chercher la période fondamentale par autocorrélation
    // Pour 16000 Hz : lag 20 = 800Hz, lag 400 = 40Hz
    const minLag = 20; // ~800 Hz max
    const maxLag = 400; // ~40 Hz min
    
    double maxCorr = 0;
    int bestLag = 100;
    
    final windowSize = min(2000, samples.length);
    
    for (int lag = minLag; lag < min(maxLag, windowSize ~/ 2); lag++) {
      double corr = 0;
      for (int i = 0; i < windowSize - lag; i++) {
        corr += samples[i] * samples[i + lag];
      }
      
      if (corr > maxCorr) {
        maxCorr = corr;
        bestLag = lag;
      }
    }
    
    // Convertir le lag en fréquence (16000 Hz sample rate pour WAV YAMNet)
    final pitch = 16000.0 / bestLag;
    
    return pitch;
  }

  /// Estime la répétition/régularité du signal
  double _estimateRepetition(List<double> samples) {
    if (samples.length < 1000) return 0.5;
    
    // Détecter les pics (passages par zéro avec amplitude élevée)
    List<int> peakPositions = [];
    final threshold = samples.map((s) => s.abs()).reduce(max) * 0.3;
    
    bool wasAbove = false;
    for (int i = 1; i < samples.length; i++) {
      final isAbove = samples[i].abs() > threshold;
      if (isAbove && !wasAbove) {
        peakPositions.add(i);
      }
      wasAbove = isAbove;
    }
    
    if (peakPositions.length < 3) return 0.3;
    
    // Calculer les intervalles entre pics
    List<int> intervals = [];
    for (int i = 1; i < peakPositions.length; i++) {
      intervals.add(peakPositions[i] - peakPositions[i - 1]);
    }
    
    // Calculer la variance des intervalles
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((i) => pow(i - mean, 2)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = sqrt(variance);
    
    // Coefficient de variation (plus bas = plus régulier)
    final cv = stdDev / mean;
    
    // Convertir en score de répétition (0-1)
    return (1.0 / (1.0 + cv)).clamp(0.0, 1.0);
  }

  /// Estime l'harmonicité du signal
  double _estimateHarmonicity(List<double> samples) {
    if (samples.length < 500) return 0.5;
    
    // Calculer le rapport entre l'énergie des pics et l'énergie totale
    final totalEnergy = samples.map((s) => s * s).reduce((a, b) => a + b);
    
    if (totalEnergy == 0) return 0.5;
    
    // Énergie des échantillons au-dessus du seuil
    final threshold = sqrt(totalEnergy / samples.length) * 1.5;
    final peakEnergy = samples
        .where((s) => s.abs() > threshold)
        .map((s) => s * s)
        .fold(0.0, (a, b) => a + b);
    
    return (peakEnergy / totalEnergy).clamp(0.0, 1.0);
  }

  /// Ajoute un échantillon d'apprentissage
  Future<void> addTrainingSample(String audioPath, BarkEmotion emotion) async {
    final features = await _extractFeatures(audioPath);
    
    if (!_trainingData.containsKey(emotion)) {
      _trainingData[emotion] = [];
    }
    
    _trainingData[emotion]!.add(features);
    
    // Limiter à 20 échantillons par émotion
    if (_trainingData[emotion]!.length > 20) {
      _trainingData[emotion]!.removeAt(0);
    }
    
    // Sauvegarder les données d'apprentissage
    await _saveTrainingData();
  }

  /// Sauvegarde les données d'apprentissage
  Future<void> _saveTrainingData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/wouf_training_data.json');
      
      final data = StringBuffer();
      data.write('{');
      
      bool first = true;
      for (final entry in _trainingData.entries) {
        if (!first) data.write(',');
        first = false;
        
        data.write('"${entry.key.name}":[');
        data.write(entry.value.map((f) => 
          '{"p":${f.pitch.toStringAsFixed(1)},"d":${f.duration.toStringAsFixed(2)},'
          '"i":${f.intensity.toStringAsFixed(2)},"r":${f.repetition.toStringAsFixed(2)},'
          '"h":${f.harmonicity.toStringAsFixed(2)}}'
        ).join(','));
        data.write(']');
      }
      
      data.write('}');
      
      await file.writeAsString(data.toString());
    } catch (e) {
      print('Erreur sauvegarde training data: $e');
    }
  }

  /// Charge les données d'apprentissage
  Future<void> _loadTrainingData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/wouf_training_data.json');
      
      if (!await file.exists()) return;
      
      final content = await file.readAsString();
      if (content.isEmpty) return;
      
      // Parse le JSON manuellement
      // Format: {"faim":[{"p":350,"d":0.3,"i":0.6,"r":0.8,"h":0.5},...], ...}
      final Map<String, dynamic> parsed = _parseJson(content);
      
      for (final entry in parsed.entries) {
        final emotionName = entry.key;
        final emotion = BarkEmotion.values.firstWhere(
          (e) => e.name == emotionName,
          orElse: () => BarkEmotion.inconnu,
        );
        
        if (emotion == BarkEmotion.inconnu) continue;
        
        final List<dynamic> featuresList = entry.value as List<dynamic>;
        final features = featuresList.map((f) {
          final map = f as Map<String, dynamic>;
          return AudioFeatures(
            pitch: (map['p'] as num).toDouble(),
            duration: (map['d'] as num).toDouble(),
            intensity: (map['i'] as num).toDouble(),
            repetition: (map['r'] as num).toDouble(),
            harmonicity: (map['h'] as num).toDouble(),
          );
        }).toList();
        
        // Limiter à 50 samples par émotion pour les perfs
        if (features.length > 50) {
          _trainingData[emotion] = features.sublist(features.length - 50);
        } else {
          _trainingData[emotion] = features;
        }
      }
      
      print('Training data chargé: ${_trainingData.length} émotions');
    } catch (e) {
      print('Erreur chargement training data: $e');
    }
  }
  
  /// Parse JSON simplifié (évite d'importer dart:convert partout)
  Map<String, dynamic> _parseJson(String json) {
    try {
      // Utiliser dart:convert pour parser
      final decoded = _decodeJson(json);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (e) {
      return {};
    }
  }
  
  dynamic _decodeJson(String source) {
    // Import implicite via le runtime Dart
    return const JsonDecoder().convert(source);
  }

  /// Retourne le nombre d'échantillons par émotion
  Map<BarkEmotion, int> getTrainingStats() {
    return _trainingData.map((key, value) => MapEntry(key, value.length));
  }

  void dispose() {
    _yamnet.dispose();
  }
}

/// Caractéristiques audio extraites
class AudioFeatures {
  final double pitch;       // Fréquence fondamentale (Hz)
  final double duration;    // Durée (secondes)
  final double intensity;   // Intensité/volume (0-1)
  final double repetition;  // Régularité des répétitions (0-1)
  final double harmonicity; // Rapport harmonique (0-1)

  AudioFeatures({
    required this.pitch,
    required this.duration,
    required this.intensity,
    required this.repetition,
    required this.harmonicity,
  });

  factory AudioFeatures.empty() => AudioFeatures(
    pitch: 350,
    duration: 0.3,
    intensity: 0.5,
    repetition: 0.5,
    harmonicity: 0.5,
  );

  /// Calcule la distance euclidienne pondérée avec d'autres caractéristiques
  double distanceTo(AudioFeatures other) {
    // Poids basés sur l'importance discriminative de chaque caractéristique
    const pitchWeight = 1.5;
    const durationWeight = 1.2;
    const intensityWeight = 1.0;
    const repetitionWeight = 1.3;
    const harmonicityWeight = 1.1;
    
    // Normalisation des valeurs
    final pitchDiff = (pitch - other.pitch) / 300; // Normaliser sur 300Hz
    final durationDiff = (duration - other.duration) / 1.0; // Normaliser sur 1s
    final intensityDiff = intensity - other.intensity;
    final repetitionDiff = repetition - other.repetition;
    final harmonicityDiff = harmonicity - other.harmonicity;
    
    return sqrt(
      pitchWeight * pitchDiff * pitchDiff +
      durationWeight * durationDiff * durationDiff +
      intensityWeight * intensityDiff * intensityDiff +
      repetitionWeight * repetitionDiff * repetitionDiff +
      harmonicityWeight * harmonicityDiff * harmonicityDiff
    );
  }

  @override
  String toString() {
    return 'AudioFeatures(pitch: ${pitch.toStringAsFixed(0)}Hz, dur: ${duration.toStringAsFixed(2)}s, '
           'int: ${(intensity * 100).toStringAsFixed(0)}%, rep: ${(repetition * 100).toStringAsFixed(0)}%, '
           'harm: ${(harmonicity * 100).toStringAsFixed(0)}%)';
  }
}

/// Résultat de classification
class ClassificationResult {
  final BarkEmotion emotion;
  final double confidence;
  final AudioFeatures features;
  final bool isDogSound;
  final String? yamnetType;
  final double? yamnetConfidence;

  ClassificationResult({
    required this.emotion,
    required this.confidence,
    required this.features,
    this.isDogSound = true,
    this.yamnetType,
    this.yamnetConfidence,
  });

  @override
  String toString() {
    return 'ClassificationResult(emotion: ${emotion.label}, confidence: ${(confidence * 100).toStringAsFixed(0)}%, '
           'isDog: $isDogSound, yamnet: $yamnetType)';
  }
}
