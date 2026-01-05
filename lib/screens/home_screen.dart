import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bark_emotion.dart';
import '../providers/app_provider.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/emotion_chip.dart';
import 'history_screen.dart';
import 'learning_screen.dart';
import 'settings_screen.dart';

/// Écran principal de l'application
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.pets, color: Color(0xFFE07A5F));
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'Wouf Wouf',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D405B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF3D405B)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            tooltip: 'Historique',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF3D405B)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Column(
              children: [
                // Zone de résultat
                Expanded(
                  child: _buildResultArea(context, provider),
                ),

                // Visualiseur audio
                if (provider.state == AppState.listening)
                  AudioVisualizer(
                    level: provider.audioLevel,
                    color: const Color(0xFFE07A5F),
                  ),

                // Bouton principal
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: _buildMainButton(context, provider),
                ),

                // Bouton apprentissage
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningScreen()),
                    ),
                    icon: const Icon(Icons.school, color: Color(0xFF81B29A)),
                    label: const Text(
                      'Mode apprentissage',
                      style: TextStyle(color: Color(0xFF81B29A)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultArea(BuildContext context, AppProvider provider) {
    switch (provider.state) {
      case AppState.loading:
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE07A5F),
          ),
        );

      case AppState.idle:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A5F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.pets,
                  size: 60,
                  color: Color(0xFFE07A5F),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Appuie sur le bouton\nquand ton chien aboie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );

      case AppState.listening:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A5F).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.hearing,
                  size: 60,
                  color: Color(0xFFE07A5F),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'J\'écoute...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE07A5F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Laisse ton chien s\'exprimer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );

      case AppState.analyzing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Color(0xFFE07A5F),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Analyse en cours...',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Je décode le message',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );

      case AppState.result:
        return _buildResultDisplay(context, provider);

      case AppState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Oups !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  provider.errorMessage ?? 'Une erreur est survenue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: provider.reset,
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Color(0xFFE07A5F)),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildResultDisplay(BuildContext context, AppProvider provider) {
    final emotion = provider.currentEmotion ?? BarkEmotion.inconnu;
    final phrase = provider.currentPhrase ?? '';
    final confidence = provider.confidence;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Émotion détectée
          EmotionChip(emotion: emotion),
          const SizedBox(height: 10),

          // Confiance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Confiance: ${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Bulle de dialogue
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(emotion.colorValue).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Color(emotion.colorValue).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '"$phrase"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF3D405B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bouton rejouer
          OutlinedButton.icon(
            onPressed: provider.replayPhrase,
            icon: const Icon(Icons.volume_up),
            label: const Text('Réécouter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE07A5F),
              side: const BorderSide(color: Color(0xFFE07A5F)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, AppProvider provider) {
    final isListening = provider.state == AppState.listening;
    final isAnalyzing = provider.state == AppState.analyzing;
    final hasResult = provider.state == AppState.result;

    if (isAnalyzing) {
      return const SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: Color(0xFFE07A5F),
        ),
      );
    }

    if (hasResult) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.reset,
          icon: const Icon(Icons.refresh),
          label: const Text('Nouvelle traduction'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE07A5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    return RecordButton(
      isRecording: isListening,
      audioLevel: provider.audioLevel,
      onTapDown: () {
        if (!isListening) provider.startListening();
      },
      onTapUp: () {
        if (isListening) provider.stopListening();
      },
    );
  }
}
