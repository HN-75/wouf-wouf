import 'dart:math';
import '../models/bark_emotion.dart';
import '../models/user_profile.dart';

/// Générateur de phrases françaises naturelles basées sur l'émotion détectée
class PhraseGenerator {
  final Random _random = Random();

  /// Génère une phrase naturelle en fonction de l'émotion et du genre de l'utilisateur
  String generate(BarkEmotion emotion, UserGender gender) {
    final phrases = _getPhrases(emotion, gender);
    return phrases[_random.nextInt(phrases.length)];
  }

  List<String> _getPhrases(BarkEmotion emotion, UserGender gender) {
    final appelation = gender.appelation;
    final appelationCourte = gender.appelationCourte;

    switch (emotion) {
      case BarkEmotion.faim:
        return [
          "Hé $appelation, j'ai trop faim là !",
          "Mon ventre gargouille, $appelationCourte !",
          "C'est l'heure des croquettes, non ?",
          "J'ai une de ces dalles, tu peux pas savoir...",
          "Ça fait combien de temps que j'ai pas mangé ? Une éternité !",
          "Hé ! Ma gamelle est vide, c'est un scandale !",
          "$appelation, je meurs de faim ici !",
          "Tu manges et moi je regarde ? Sérieux ?",
          "Une petite friandise ? Allez, juste une...",
          "Mon estomac fait des bruits bizarres là...",
        ];

      case BarkEmotion.jouer:
        return [
          "Allez $appelation, on joue !",
          "Lance la balle ! Lance la balle ! LANCE LA BALLE !",
          "Je m'ennuie trop là, viens jouer !",
          "Hé $appelationCourte, t'as vu ma balle ? Elle est géniale !",
          "Course-poursuite ? Je te laisse même de l'avance !",
          "J'ai trop d'énergie, faut que ça sorte !",
          "On fait la bagarre pour de faux ?",
          "Tire sur la corde ! Allez, tire !",
          "Cache-cache ? Je te trouve toujours de toute façon !",
          "Je suis prêt à jouer pendant des heures !",
        ];

      case BarkEmotion.peur:
        return [
          "$appelation, j'ai peur là...",
          "C'était quoi ce bruit ?! Protège-moi !",
          "Je me sens pas en sécurité...",
          "Reste avec moi, $appelationCourte...",
          "Y'a un truc bizarre, je le sens...",
          "Je peux me cacher derrière toi ?",
          "Ça me fait flipper ce truc...",
          "Fais-le partir, $appelation !",
          "Je tremble, tu vois pas ?",
          "Câlin ? J'ai besoin d'un câlin là...",
        ];

      case BarkEmotion.sortir:
        return [
          "Hé $appelation, j'veux sortir !",
          "Pipi ! C'est urgent là !",
          "La porte, $appelationCourte, LA PORTE !",
          "Je dois aller dehors, maintenant !",
          "Ça presse, ça presse, ça presse !",
          "J'ai besoin de prendre l'air !",
          "Une petite balade ? Allez, dis oui !",
          "Je veux aller renifler des trucs dehors !",
          "Ouvre la porte, je t'en supplie !",
          "Si tu m'ouvres pas, je réponds de rien...",
        ];

      case BarkEmotion.douleur:
        return [
          "$appelation, j'ai mal...",
          "Aïe, quelque chose me fait souffrir...",
          "Je me sens pas bien du tout...",
          "Ça fait mal là, $appelationCourte...",
          "J'ai besoin d'aide, je crois...",
          "Quelque chose cloche avec moi...",
          "Je suis pas dans mon assiette...",
          "Tu peux regarder ? Ça me lance...",
          "Je souffre, $appelation...",
          "Faut peut-être aller chez le véto...",
        ];

      case BarkEmotion.joie:
        return [
          "T'es revenu $appelation ! T'ES REVENU !",
          "Je suis trop content là !",
          "C'est le plus beau jour de ma vie !",
          "Je t'aime trop, $appelationCourte !",
          "OUIIIII ! C'est génial !",
          "Ma queue va se décrocher tellement je suis heureux !",
          "T'es le meilleur $appelation du monde !",
          "Je pourrais exploser de bonheur !",
          "Cette journée est parfaite !",
          "Rien que de te voir, ça me rend fou de joie !",
        ];

      case BarkEmotion.inconnu:
        return [
          "Wouf ? Je sais pas trop ce que je veux...",
          "Hé $appelation, écoute-moi !",
          "J'essaie de te dire un truc...",
          "Tu comprends ce que je dis ?",
          "C'est compliqué à expliquer en wouf...",
          "Fais attention à moi, $appelationCourte !",
          "Y'a un truc, mais je sais pas quoi...",
          "Je communique, tu vois ?",
        ];
    }
  }
}
