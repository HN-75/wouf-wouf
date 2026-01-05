import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bark_emotion.dart';
import '../providers/app_provider.dart';
import '../widgets/audio_visualizer.dart';

/// Écran du mode apprentissage pour entraîner le modèle
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  bool _isRecording = false;
  String? _recordedPath;
  BarkEmotion? _selectedEmotion;
  double _audioLevel = 0.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    provider.audioRecorder.amplitudeStream.listen((level) {
      if (mounted) {
        setState(() => _audioLevel = level);
      }
    });
  }

  Future<void> _startRecording() async {
    final provider = context.read<AppProvider>();
    final hasPermission = await provider.audioRecorder.hasPermission();
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission micro requise')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _selectedEmotion = null;
    });

    await provider.audioRecorder.startRecording();
  }

  Future<void> _stopRecording() async {
    final provider = context.read<AppProvider>();
    final path = await provider.audioRecorder.stopRecording();

    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
  }

  Future<void> _saveTrainingSample() async {
    if (_recordedPath == null || _selectedEmotion == null) return;

    final provider = context.read<AppProvider>();
    await provider.addTrainingSample(_recordedPath!, _selectedEmotion!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échantillon "${_selectedEmotion!.label}" enregistré'),
          backgroundColor: const Color(0xFF81B29A),
        ),
      );

      setState(() {
        _recordedPath = null;
        _selectedEmotion = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3D405B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mode apprentissage',
          style: TextStyle(
            color: Color(0xFF3D405B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explication
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF81B29A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF81B29A).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF81B29A),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enregistre les aboiements de ton chien et dis-moi ce qu\'ils signifient pour améliorer la précision.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Statistiques d'apprentissage
            _buildTrainingStats(),
            const SizedBox(height: 30),

            // Zone d'enregistrement
            Center(
              child: Column(
                children: [
                  // Visualiseur audio
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AudioVisualizer(
                        level: _audioLevel,
                        color: const Color(0xFF81B29A),
                      ),
                    ),

                  // Bouton d'enregistrement
                  GestureDetector(
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecording(),
                    onTapCancel: _stopRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 100 : 80,
                      height: _isRecording ? 100 : 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF81B29A),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red
                                    : const Color(0xFF81B29A))
                                .withOpacity(0.4),
                            blurRadius: _isRecording ? 25 : 15,
                            spreadRadius: _isRecording ? 5 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _isRecording
                        ? 'Relâche pour arrêter'
                        : 'Maintiens pour enregistrer',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Sélection de l'émotion (si enregistrement fait)
            if (_recordedPath != null) ...[
              const Text(
                'Que signifie cet aboiement ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D405B),
                ),
              ),
              const SizedBox(height: 15),
              _buildEmotionSelector(),
              const SizedBox(height: 20),

              // Bouton de sauvegarde
              if (_selectedEmotion != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveTrainingSample,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer cet apprentissage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81B29A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingStats() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.classifier.getTrainingStats();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Échantillons enregistrés',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D405B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BarkEmotion.values
                    .where((e) => e != BarkEmotion.inconnu)
                    .map((emotion) {
                  final count = stats[emotion] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(emotion.colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${emotion.label}: $count',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(emotion.colorValue),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: BarkEmotion.values
          .where((e) => e != BarkEmotion.inconnu)
          .map((emotion) {
        final isSelected = _selectedEmotion == emotion;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedEmotion = emotion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(emotion.colorValue)
                  : Color(emotion.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Color(emotion.colorValue),
                width: 2,
              ),
            ),
            child: Text(
              emotion.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(emotion.colorValue),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
