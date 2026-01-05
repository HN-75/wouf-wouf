import 'package:flutter/material.dart';
import '../models/bark_emotion.dart';

/// Widget affichant l'émotion détectée avec son icône
class EmotionChip extends StatelessWidget {
  final BarkEmotion emotion;
  final bool showLabel;
  final double size;

  const EmotionChip({
    super.key,
    required this.emotion,
    this.showLabel = true,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Color(emotion.colorValue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Color(emotion.colorValue).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            emotion.iconPath,
            width: size * 0.6,
            height: size * 0.6,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si l'image n'existe pas
              return Icon(
                emotion.fallbackIcon,
                size: size * 0.6,
                color: Color(emotion.colorValue),
              );
            },
          ),
          if (showLabel) ...[
            const SizedBox(width: 10),
            Text(
              emotion.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(emotion.colorValue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Extension pour les chemins d'icônes
extension BarkEmotionIconExtension on BarkEmotion {
  String get iconPath {
    switch (this) {
      case BarkEmotion.faim:
        return 'assets/images/icon_faim.png';
      case BarkEmotion.jouer:
        return 'assets/images/icon_jouer.png';
      case BarkEmotion.peur:
        return 'assets/images/icon_peur.png';
      case BarkEmotion.sortir:
        return 'assets/images/icon_sortir.png';
      case BarkEmotion.douleur:
        return 'assets/images/icon_douleur.png';
      case BarkEmotion.joie:
        return 'assets/images/icon_joie.png';
      case BarkEmotion.inconnu:
        return 'assets/images/icon_inconnu.png';
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case BarkEmotion.faim:
        return Icons.restaurant;
      case BarkEmotion.jouer:
        return Icons.sports_tennis;
      case BarkEmotion.peur:
        return Icons.warning_amber;
      case BarkEmotion.sortir:
        return Icons.door_front_door;
      case BarkEmotion.douleur:
        return Icons.healing;
      case BarkEmotion.joie:
        return Icons.favorite;
      case BarkEmotion.inconnu:
        return Icons.help_outline;
    }
  }
}
