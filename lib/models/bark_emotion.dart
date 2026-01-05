/// Émotions détectables dans les aboiements
enum BarkEmotion {
  faim,
  jouer,
  peur,
  sortir,
  douleur,
  joie,
  inconnu,
}

/// Extension pour les labels et icônes
extension BarkEmotionExtension on BarkEmotion {
  String get label {
    switch (this) {
      case BarkEmotion.faim:
        return 'Faim';
      case BarkEmotion.jouer:
        return 'Jouer';
      case BarkEmotion.peur:
        return 'Peur';
      case BarkEmotion.sortir:
        return 'Sortir';
      case BarkEmotion.douleur:
        return 'Douleur';
      case BarkEmotion.joie:
        return 'Joie';
      case BarkEmotion.inconnu:
        return 'Inconnu';
    }
  }

  String get emoji {
    switch (this) {
      case BarkEmotion.faim:
        return '🍖';
      case BarkEmotion.jouer:
        return '🎾';
      case BarkEmotion.peur:
        return '😰';
      case BarkEmotion.sortir:
        return '🚪';
      case BarkEmotion.douleur:
        return '🩹';
      case BarkEmotion.joie:
        return '🥳';
      case BarkEmotion.inconnu:
        return '❓';
    }
  }

  /// Couleur associée à l'émotion
  int get colorValue {
    switch (this) {
      case BarkEmotion.faim:
        return 0xFFFF9800; // Orange
      case BarkEmotion.jouer:
        return 0xFF4CAF50; // Vert
      case BarkEmotion.peur:
        return 0xFF9C27B0; // Violet
      case BarkEmotion.sortir:
        return 0xFF2196F3; // Bleu
      case BarkEmotion.douleur:
        return 0xFFF44336; // Rouge
      case BarkEmotion.joie:
        return 0xFFFFEB3B; // Jaune
      case BarkEmotion.inconnu:
        return 0xFF9E9E9E; // Gris
    }
  }
}
