import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';

/// Écran d'historique des traductions
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
          'Historique',
          style: TextStyle(
            color: Color(0xFF3D405B),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFF3D405B)),
                onPressed: () => _showClearDialog(context, provider),
                tooltip: 'Effacer l\'historique',
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final history = provider.history;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.history,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune traduction',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Les traductions apparaîtront ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return _buildHistoryCard(entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(TranslationEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // En-tête avec émotion et date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A5F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.emotion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE07A5F),
                  ),
                ),
              ),
              Text(
                _formatDate(entry.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Phrase traduite
          Text(
            '"${entry.phrase}"',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Color(0xFF3D405B),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Confiance
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Confiance: ${(entry.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showClearDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique ?'),
        content: const Text(
          'Cette action supprimera toutes les traductions enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
