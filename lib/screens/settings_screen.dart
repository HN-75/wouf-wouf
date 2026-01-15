import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import 'bluetooth_screen.dart';

/// Écran des paramètres
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'Paramètres',
          style: TextStyle(
            color: Color(0xFF3D405B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section Profil
              _buildSectionTitle('Profil'),
              _buildProfileCard(context, provider),
              const SizedBox(height: 24),

              // Section Bluetooth
              _buildSectionTitle('Micro externe'),
              _buildBluetoothCard(context, provider),
              const SizedBox(height: 24),

              // Section À propos
              _buildSectionTitle('À propos'),
              _buildAboutCard(context),
              const SizedBox(height: 24),

              // Version
              Center(
                child: Text(
                  'Wouf Wouf v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '100% Offline - Aucune donnée envoyée',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3D405B),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppProvider provider) {
    final profile = provider.profile;

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
        children: [
          // Nom du chien
          _buildSettingRow(
            icon: Icons.pets,
            title: 'Nom du chien',
            value: profile.dogName ?? 'Non défini',
            onTap: () => _showDogNameDialog(context, provider),
          ),
          const Divider(height: 24),
          
          // Genre
          _buildSettingRow(
            icon: Icons.person,
            title: 'Appelation',
            value: profile.gender.label,
            onTap: () => _showGenderDialog(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothCard(BuildContext context, AppProvider provider) {
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
      child: _buildSettingRow(
        icon: Icons.bluetooth,
        title: 'Micro Bluetooth',
        value: provider.isBluetoothConnected
            ? provider.bluetoothDeviceName ?? 'Connecté'
            : 'Non connecté',
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: provider.isBluetoothConnected
                ? const Color(0xFF81B29A)
                : Colors.grey.shade400,
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BluetoothScreen()),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
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
        children: [
          _buildSettingRow(
            icon: Icons.info_outline,
            title: 'Comment ça marche',
            onTap: () => _showHowItWorksDialog(context),
          ),
          const Divider(height: 24),
          _buildSettingRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Confidentialité',
            onTap: () => _showPrivacyDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE07A5F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE07A5F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF3D405B),
                    ),
                  ),
                  if (value != null)
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
    );
  }

  void _showDogNameDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.profile.dogName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom du chien'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Rex, Médor, Luna...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.updateProfile(provider.profile.copyWith(dogName: controller.text));
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showGenderDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment ton chien t\'appelle ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserGender.values.map((gender) {
            return ListTile(
              title: Text(gender.label),
              subtitle: Text('"Hé ${gender.appelation}..."'),
              leading: Radio<UserGender>(
                value: gender,
                groupValue: provider.profile.gender,
                onChanged: (value) {
                  if (value != null) {
                    provider.updateProfile(provider.profile.copyWith(gender: value));
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                provider.updateProfile(provider.profile.copyWith(gender: gender));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment ça marche ?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Détection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'L\'app utilise YAMNet, un modèle de Google entraîné sur des millions de sons, pour détecter les aboiements.',
              ),
              SizedBox(height: 12),
              Text(
                '2. Analyse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Les caractéristiques audio (fréquence, durée, intensité) sont analysées pour déterminer l\'émotion.',
              ),
              SizedBox(height: 12),
              Text(
                '3. Apprentissage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Le mode apprentissage permet d\'améliorer la précision pour TON chien spécifiquement.',
              ),
              SizedBox(height: 12),
              Text(
                '4. Traduction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Une phrase naturelle en français est générée et lue à voix haute.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confidentialité'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '100% Offline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Wouf Wouf fonctionne entièrement sur ton téléphone. Aucune donnée n\'est envoyée sur internet.',
              ),
              SizedBox(height: 16),
              Text(
                'Données stockées localement :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Ton profil (nom du chien, préférences)'),
              Text('• Historique des traductions'),
              Text('• Échantillons d\'apprentissage'),
              SizedBox(height: 16),
              Text(
                'Tu peux supprimer toutes tes données à tout moment depuis les paramètres.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
