import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';

/// Écran d'onboarding pour configurer le profil
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _dogNameController = TextEditingController();
  UserGender _selectedGender = UserGender.neutre;
  int _currentPage = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _dogNameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    final provider = context.read<AppProvider>();
    final newProfile = provider.profile.copyWith(
      dogName: _dogNameController.text.isEmpty ? null : _dogNameController.text,
      gender: _selectedGender,
      onboardingComplete: true,
    );
    await provider.updateProfile(newProfile);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentPage
                          ? const Color(0xFFE07A5F)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(),
                  _buildGenderPage(),
                  _buildDogNamePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo de l'app
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE07A5F).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 80,
                    color: Color(0xFFE07A5F),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Bienvenue sur\nWouf Wouf',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D405B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'L\'app qui traduit les aboiements\nde ton chien en français',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'C\'est parti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Comment ton chien\ndoit t\'appeler ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D405B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pour personnaliser les traductions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          
          // Options de genre
          _buildGenderOption(
            UserGender.homme,
            Icons.person,
            'Maître / Boss',
            'Hé maître, j\'ai faim !',
          ),
          const SizedBox(height: 15),
          _buildGenderOption(
            UserGender.femme,
            Icons.person_outline,
            'Maîtresse / Ma belle',
            'Hé maîtresse, j\'ai faim !',
          ),
          const SizedBox(height: 15),
          _buildGenderOption(
            UserGender.neutre,
            Icons.person_2,
            'Humain / Toi',
            'Hé humain, j\'ai faim !',
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Suivant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    UserGender gender,
    IconData icon,
    String title,
    String example,
  ) {
    final isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFE07A5F).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFE07A5F)
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFE07A5F).withOpacity(0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected 
                    ? const Color(0xFFE07A5F)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? const Color(0xFF3D405B)
                          : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    example,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFE07A5F),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDogNamePage() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
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
          const Text(
            'Comment s\'appelle\nton chien ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D405B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '(Optionnel)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 30),
          
          TextField(
            controller: _dogNameController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF3D405B),
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Rex, Médor, Luna...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFE07A5F), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
          
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _complete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Commencer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          
          TextButton(
            onPressed: _complete,
            child: Text(
              'Passer cette étape',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
