import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de visualisation du niveau audio
class AudioVisualizer extends StatefulWidget {
  final double level;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.level,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (index) {
              // Créer un effet de vague
              final phase = (index / 20) * math.pi * 2;
              final wave = math.sin(phase + _controller.value * math.pi * 2);
              final heightFactor = (widget.level * 0.7 + wave * 0.3 * widget.level)
                  .clamp(0.1, 1.0);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 4,
                height: 50 * heightFactor,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5 + heightFactor * 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Widget bouton d'enregistrement animé
class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final double audioLevel;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onTapDown,
    required this.onTapUp,
    this.audioLevel = 0.0,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => widget.onTapDown(),
      onTapUp: (_) => widget.onTapUp(),
      onTapCancel: widget.onTapUp,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseScale = widget.isRecording
              ? 1.0 + _pulseController.value * 0.1 + widget.audioLevel * 0.2
              : 1.0;

          return Transform.scale(
            scale: pulseScale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? Colors.red
                    : Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? Colors.red
                            : Theme.of(context).primaryColor)
                        .withOpacity(0.4),
                    blurRadius: widget.isRecording ? 30 : 15,
                    spreadRadius: widget.isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop : Icons.mic,
                size: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
