# Wouf Wouf - Traducteur d'Aboiements

Application mobile Flutter qui traduit les aboiements de votre chien en phrases françaises naturelles. 100% offline, aucune donnée envoyée dans le cloud.

## Fonctionnalités

- **Détection d'aboiements** : Utilise YAMNet (modèle Google pré-entraîné) pour détecter les sons de chien
- **Classification émotionnelle** : Analyse les caractéristiques audio (pitch, durée, intensité) pour déterminer l'émotion
- **6 émotions détectées** : Faim, Jouer, Peur, Sortir, Douleur, Joie
- **Phrases naturelles** : Génère des phrases en français familier adaptées au genre de l'utilisateur
- **Voix française** : TTS offline avec voix naturelle
- **Mode apprentissage** : Améliore la précision avec les aboiements de VOTRE chien
- **Bluetooth LE** : Support pour micro externe ou collier connecté
- **100% Offline** : Aucune connexion internet requise

## Installation

### Prérequis

- Flutter SDK 3.10+
- Android SDK 24+ (Android 7.0 Nougat minimum)
- Java 17

### Build

```bash
# Cloner le repo
git clone https://github.com/VOTRE_USERNAME/wouf_wouf.git
cd wouf_wouf

# Installer les dépendances
flutter pub get

# Build APK release
flutter build apk --release

# L'APK se trouve dans build/app/outputs/flutter-apk/app-release.apk
```

## Architecture

```
lib/
├── main.dart                 # Point d'entrée
├── models/
│   ├── bark_emotion.dart     # Énumération des émotions
│   └── user_profile.dart     # Profil utilisateur
├── providers/
│   └── app_provider.dart     # État global de l'app
├── screens/
│   ├── home_screen.dart      # Écran principal
│   ├── onboarding_screen.dart # Configuration initiale
│   ├── history_screen.dart   # Historique des traductions
│   ├── learning_screen.dart  # Mode apprentissage
│   ├── settings_screen.dart  # Paramètres
│   └── bluetooth_screen.dart # Connexion Bluetooth
├── services/
│   ├── audio_recorder_service.dart  # Enregistrement audio
│   ├── bark_classifier_service.dart # Classification ML
│   ├── yamnet_service.dart          # Intégration YAMNet
│   ├── phrase_generator.dart        # Génération de phrases
│   ├── tts_service.dart             # Text-to-Speech
│   ├── bluetooth_service.dart       # Bluetooth LE
│   └── storage_service.dart         # Stockage local
└── widgets/
    ├── audio_visualizer.dart # Visualisation audio
    └── emotion_chip.dart     # Affichage des émotions
```

## Comment ça marche

### 1. Détection d'aboiement (YAMNet)

Le modèle YAMNet de Google (521 classes audio) détecte si le son enregistré est bien un aboiement de chien. Classes utilisées :
- Dog (69)
- Bark (70)
- Howl (72)
- Growling (74)
- Whimper (75)

### 2. Classification émotionnelle

L'analyse des caractéristiques audio permet de déterminer l'émotion :

| Caractéristique | Faim | Jouer | Peur | Sortir | Douleur | Joie |
|-----------------|------|-------|------|--------|---------|------|
| Pitch | Moyen | Haut | Haut | Moyen | Bas | Haut |
| Durée | Court | Court | Long | Moyen | Long | Court |
| Intensité | Moyenne | Haute | Basse | Haute | Basse | Haute |
| Répétition | Régulière | Rapide | Irrégulière | Régulière | Lente | Rapide |

### 3. Mode apprentissage

L'utilisateur peut améliorer la précision en étiquetant manuellement les aboiements de son chien. Les données sont stockées localement et utilisées pour affiner la classification.

## Personnalisation des phrases

Les phrases sont adaptées selon le genre choisi par l'utilisateur :

- **Homme** : "Hé maître, j'ai faim !", "Boss, on joue ?"
- **Femme** : "Hé maîtresse, j'ai faim !", "Ma belle, on joue ?"
- **Neutre** : "Hé humain, j'ai faim !", "Toi, on joue ?"

## Bluetooth LE

L'app supporte les micros Bluetooth LE pour une meilleure qualité audio ou pour un futur collier connecté. Protocole standard BLE avec caractéristiques audio.

## Permissions requises

- `RECORD_AUDIO` : Enregistrement des aboiements
- `BLUETOOTH_*` : Connexion micro externe
- `WRITE_EXTERNAL_STORAGE` : Sauvegarde des enregistrements

## Roadmap

- [ ] Fine-tuning du modèle avec dataset d'aboiements réels
- [ ] Support iOS
- [ ] Collier connecté avec capteurs (température, rythme cardiaque)
- [ ] Historique avec graphiques d'humeur
- [ ] Partage des traductions sur les réseaux sociaux

## Licence

MIT License - Libre d'utilisation et de modification.

## Crédits

- YAMNet : Google Research
- Flutter : Google
- TensorFlow Lite : Google
- Icônes générées par IA

---

Fait avec amour pour nos amis à quatre pattes.
