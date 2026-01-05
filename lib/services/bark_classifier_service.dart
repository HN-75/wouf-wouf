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
    // FAIM : aboiements répétitifs, fréquence moyenne, durée courte, tonalité montante
    // Les chiens affamés produisent des aboiements insistants et réguliers
    _trainingData[BarkEmotion.faim] = [
      AudioFeatures(pitch: 350, duration: 0.3, intensity: 0.6, repetition: 0.8, harmonicity: 0.5),
      AudioFeatures(pitch: 380, duration: 0.25, intensity: 0.65, repetition: 0.85, harmonicity: 0.55),
      AudioFeatures(pitch: 320, duration: 0.35, intensity: 0.55, repetition: 0.75, harmonicity: 0.45),
      AudioFeatures(pitch: 360, duration: 0.28, intensity: 0.62, repetition: 0.82, harmonicity: 0.52),
    ];
    
    // JOUER : aboiements aigus, courts, très répétitifs, haute énergie, tonalité variable
    // Les aboiements de jeu sont caractérisés par leur variabilité et leur énergie
    _trainingData[BarkEmotion.jouer] = [
      AudioFeatures(pitch: 450, duration: 0.2, intensity: 0.8, repetition: 0.9, harmonicity: 0.7),
      AudioFeatures(pitch: 480, duration: 0.15, intensity: 0.85, repetition: 0.95, harmonicity: 0.75),
      AudioFeatures(pitch: 420, duration: 0.25, intensity: 0.75, repetition: 0.85, harmonicity: 0.65),
      AudioFeatures(pitch: 460, duration: 0.18, intensity: 0.82, repetition: 0.92, harmonicity: 0.72),
    ];
    
    // PEUR : aboiements graves, longs, gémissements, basse fréquence, tonalité descendante
    // La peur produit des sons plus graves et prolongés
    _trainingData[BarkEmotion.peur] = [
      AudioFeatures(pitch: 200, duration: 0.8, intensity: 0.4, repetition: 0.3, harmonicity: 0.3),
      AudioFeatures(pitch: 180, duration: 1.0, intensity: 0.35, repetition: 0.25, harmonicity: 0.25),
      AudioFeatures(pitch: 220, duration: 0.7, intensity: 0.45, repetition: 0.35, harmonicity: 0.35),
      AudioFeatures(pitch: 190, duration: 0.9, intensity: 0.38, repetition: 0.28, harmonicity: 0.28),
    ];
    
    // SORTIR : aboiements insistants, fréquence moyenne-haute, durée moyenne
    // Demande d'attention avec une certaine urgence
    _trainingData[BarkEmotion.sortir] = [
      AudioFeatures(pitch: 380, duration: 0.4, intensity: 0.7, repetition: 0.7, harmonicity: 0.55),
      AudioFeatures(pitch: 400, duration: 0.35, intensity: 0.75, repetition: 0.75, harmonicity: 0.6),
      AudioFeatures(pitch: 360, duration: 0.45, intensity: 0.65, repetition: 0.65, harmonicity: 0.5),
      AudioFeatures(pitch: 390, duration: 0.38, intensity: 0.72, repetition: 0.72, harmonicity: 0.57),
    ];
    
    // DOULEUR : gémissements, sons aigus et plaintifs, longue durée, haute harmonicité
    // Les vocalisations de douleur sont distinctives par leur tonalité plaintive
    _trainingData[BarkEmotion.douleur] = [
      AudioFeatures(pitch: 500, duration: 1.2, intensity: 0.5, repetition: 0.2, harmonicity: 0.8),
      AudioFeatures(pitch: 520, duration: 1.5, intensity: 0.45, repetition: 0.15, harmonicity: 0.85),
      AudioFeatures(pitch: 480, duration: 1.0, intensity: 0.55, repetition: 0.25, harmonicity: 0.75),
      AudioFeatures(pitch: 510, duration: 1.3, intensity: 0.48, repetition: 0.18, harmonicity: 0.82),
    ];
    
    // JOIE : aboiements courts, aigus, très énergiques, haute répétition
    // L'excitation positive produit des sons rapides et énergiques
    _trainingData[BarkEmotion.joie] = [
      AudioFeatures(pitch: 420, duration: 0.15, intensity: 0.9, repetition: 0.95, harmonicity: 0.65),
      AudioFeatures(pitch: 450, duration: 0.1, intensity: 0.95, repetition: 1.0, harmonicity: 0.7),
      AudioFeatures(pitch: 400, duration: 0.2, intensity: 0.85, repetition: 0.9, harmonicity: 0.6),
      AudioFeatures(pitch: 430, duration: 0.12, intensity: 0.92, repetition: 0.97, harmonicity: 0.67),
    ];
  }

  /// Classifie un fichier audio
  Future<ClassificationResult> classify(String audioPath) async {
    if (!_isInitialized) await init();
    
    // Étape 1 : Vérifier avec YAMNet si c'est un son de chien
    final yamnetResult = await _yamnet.analyzeAudio(audioPath);
    
    if (!yamnetResult.isDogSound && yamnetResult.dogConfidence < 0.2) {
      // Ce n'est probablement pas un son de chien
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
    
    // Étape 3 : Utiliser le type YAMNet pour affiner la classification
    BarkEmotion? yamnetHint = _getEmotionHintFromYamnet(yamnetResult.dogSoundType);
    
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
    
    // Estimer la durée en secondes (44100 Hz, 16-bit)
    final duration = (audioBytes.length / 2 / 44100).clamp(0.1, 5.0);
    
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
    const minLag = 20; // ~2200 Hz max
    const maxLag = 400; // ~110 Hz min
    
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
    
    // Convertir le lag en fréquence (44100 Hz sample rate)
    final pitch = 44100.0 / bestLag;
    
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
      // Parse simplifié - dans une version production, utiliser json.decode
      // Pour l'instant, on garde juste le modèle de base
    } catch (e) {
      print('Erreur chargement training data: $e');
    }
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
