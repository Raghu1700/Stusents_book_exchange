import 'package:flutter/material.dart';
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/screens/home/home_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'services/auth_service.dart';
import 'package:rive_animation/screens/admin/sample_books_screen.dart';

// Global auth service instance
late AuthService authService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    if (kIsWeb) {
      // For web, we need to provide the Firebase options explicitly
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBl5Q_h1UBez78UZnj2kCASqBCowKRBh3A",
          appId: "1:933957299614:web:f73a673baf6d0caf23fa8f",
          messagingSenderId: "933957299614",
          projectId: "hitagyana-5d160",
          authDomain: "hitagyana-5d160.firebaseapp.com",
          storageBucket: "hitagyana-5d160.firebasestorage.app",
          measurementId: "G-90FGMF4SCJ",
        ),
      );
      print("Firebase initialized for web with explicit options");
    } else {
      // For mobile platforms
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print("Firebase initialized for mobile successfully");
      } catch (e) {
        print("Error initializing Firebase for mobile: $e");
        throw e;
      }
    }

    // Initialize auth service
    authService = AuthService();
    print("Authentication service initialized");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Print stack trace for debugging
    print(StackTrace.current);

    // Create auth service even if Firebase init fails
    authService = AuthService();
    print("Authentication service initialized after error");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Book Exchange',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF3D5AF1), // Primary blue color
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF22B07D), // Secondary green color
        ),
        fontFamily: "Intel",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3D5AF1),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),
      home: const AuthenticationWrapper(), // Go directly to the normal app
    );
  }
}

// Debug navigator for testing and development - no longer used by default
class DebugNavigator extends StatelessWidget {
  const DebugNavigator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Debug Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthenticationWrapper(),
                  ),
                );
              },
              child: const Text('Go to Normal App'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SampleBooksScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Add Sample Books'),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget that checks authentication state
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    // Listen for authentication state changes
    authService.authStateChanges.listen((User? user) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    });
  }

  Future<void> _checkCurrentUser() async {
    // Wait a moment to allow Firebase to initialize completely
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final currentUser = authService.getCurrentUser();
      setState(() {
        _user = currentUser;
        _isLoading = false;
      });
      print("Current user: ${currentUser?.email ?? 'None'}");
    } catch (e) {
      print("Error checking current user: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If we have a user, go directly to the home screen
    if (_user != null) {
      return const HomePage();
    }

    // Otherwise, show the onboarding screen
    return const OnbodingScreen();
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
