import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  // Global error handler pour catch toutes les erreurs non gérées
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Forcer l'orientation portrait
    await SystemChrome.setPreferredOrientations([
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
    
    // Catch les erreurs Flutter (UI)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
    };
    
    runApp(const WoufWoufApp());
  }, (error, stackTrace) {
    // Catch les erreurs Dart non gérées (async, etc.)
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack: $stackTrace');
  });
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
                  SizedBox(height: 20),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3D405B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Écran d'erreur fatale (ne devrait jamais arriver avec les protections)
        if (provider.state == AppState.error && provider.errorMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF8F0),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Color(0xFFE07A5F),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Oups !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D405B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage ?? 'Une erreur est survenue',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3D405B),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => provider.init(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
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
