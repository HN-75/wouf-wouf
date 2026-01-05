import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Forcer l'orientation portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Barre de statut transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const WoufWoufApp());
}

/// Application principale Wouf Wouf
class WoufWoufApp extends StatelessWidget {
  const WoufWoufApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Wouf Wouf',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE07A5F),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF8F0),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF3D405B)),
            titleTextStyle: TextStyle(
              color: Color(0xFF3D405B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A5F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE07A5F),
            ),
          ),
          fontFamily: 'Roboto',
        ),
        home: const AppWrapper(),
      ),
    );
  }
}

/// Wrapper pour gérer l'initialisation et l'onboarding
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Écran de chargement
        if (provider.state == AppState.loading) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF8F0),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(
                    Icons.pets,
                    size: 80,
                    color: Color(0xFFE07A5F),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Wouf Wouf',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D405B),
                    ),
                  ),
                  SizedBox(height: 30),
                  CircularProgressIndicator(
                    color: Color(0xFFE07A5F),
                  ),
                ],
              ),
            ),
          );
        }

        // Onboarding ou écran principal
        if (provider.needsOnboarding) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
