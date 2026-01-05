import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Service de stockage local pour les préférences utilisateur
class StorageService {
  static const String _profileKey = 'user_profile';
  static const String _translationHistoryKey = 'translation_history';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Sauvegarde le profil utilisateur
  Future<void> saveProfile(UserProfile profile) async {
    await _prefs?.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  /// Charge le profil utilisateur
  Future<UserProfile?> loadProfile() async {
    final json = _prefs?.getString(_profileKey);
    if (json == null) return null;
    
    try {
      return UserProfile.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde une traduction dans l'historique
  Future<void> addToHistory(TranslationEntry entry) async {
    final history = await getHistory();
    history.insert(0, entry);
    
    // Garder seulement les 100 dernières traductions
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    final jsonList = history.map((e) => e.toJson()).toList();
    await _prefs?.setString(_translationHistoryKey, jsonEncode(jsonList));
  }

  /// Récupère l'historique des traductions
  Future<List<TranslationEntry>> getHistory() async {
    final json = _prefs?.getString(_translationHistoryKey);
    if (json == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => TranslationEntry.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Efface tout l'historique
  Future<void> clearHistory() async {
    await _prefs?.remove(_translationHistoryKey);
  }

  /// Charge l'historique (alias pour getHistory)
  Future<List<TranslationEntry>> loadHistory() async {
    return await getHistory();
  }

  /// Sauvegarde l'historique complet
  Future<void> saveHistory(List<TranslationEntry> history) async {
    final jsonList = history.map((e) => e.toJson()).toList();
    await _prefs?.setString(_translationHistoryKey, jsonEncode(jsonList));
  }

  /// Efface toutes les données
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

/// Entrée dans l'historique des traductions
class TranslationEntry {
  final DateTime timestamp;
  final String emotion;
  final String phrase;
  final double confidence;
  final String? audioPath;

  TranslationEntry({
    required this.timestamp,
    required this.emotion,
    required this.phrase,
    required this.confidence,
    this.audioPath,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'emotion': emotion,
    'phrase': phrase,
    'confidence': confidence,
    'audioPath': audioPath,
  };

  factory TranslationEntry.fromJson(Map<String, dynamic> json) => TranslationEntry(
    timestamp: DateTime.parse(json['timestamp']),
    emotion: json['emotion'],
    phrase: json['phrase'],
    confidence: json['confidence'],
    audioPath: json['audioPath'],
  );
}
