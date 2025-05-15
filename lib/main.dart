import 'package:flutter/material.dart';
import 'package:rive_animation/screens/onboding/onboding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/screens/home/home_screen.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Flag to use Firebase or mock authentication
const bool USE_FIREBASE_AUTH = true;
const bool USE_AUTH_EMULATOR =
    false; // Set to true if running firebase emulator

// Abstract auth service interface
abstract class AuthService {
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      {required String email, required String password, String? phoneNumber});
  Future<Map<String, dynamic>> createUserWithEmailAndPassword(
      {required String email, required String password, String? phoneNumber});
  User? getCurrentUser();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}

// Firebase implementation
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      {required String email,
      required String password,
      String? phoneNumber}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign-in is successful and we have a phone number, update the user profile
      if (phoneNumber != null && userCredential.user != null) {
        // Store the phone number in a custom claim or user metadata
        // Note: This would normally require a backend function to update custom claims
        // For now, we'll just update the displayName as a workaround
        await userCredential.user!.updateProfile(
          displayName: phoneNumber,
        );
      }

      return {
        'success': true,
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
        'phoneNumber': phoneNumber,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createUserWithEmailAndPassword(
      {required String email,
      required String password,
      String? phoneNumber}) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If registration is successful and we have a phone number, update the user profile
      if (phoneNumber != null && userCredential.user != null) {
        // Store the phone number in the displayName field
        await userCredential.user!.updateProfile(
          displayName: phoneNumber,
        );
      }

      return {
        'success': true,
        'uid': userCredential.user?.uid,
        'email': userCredential.user?.email,
        'phoneNumber': phoneNumber,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  @override
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

// Mock implementation for development without Firebase
class MockAuthService implements AuthService {
  User? _currentUser;
  String? _phoneNumber;

  @override
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      {required String email,
      required String password,
      String? phoneNumber}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final uid = 'mock-uid-${DateTime.now().millisecondsSinceEpoch}';
    _phoneNumber = phoneNumber;
    _currentUser = MockUser(uid: uid, email: email, phoneNumber: phoneNumber);

    return {
      'success': true,
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  Future<Map<String, dynamic>> createUserWithEmailAndPassword(
      {required String email,
      required String password,
      String? phoneNumber}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final uid = 'mock-uid-${DateTime.now().millisecondsSinceEpoch}';
    _phoneNumber = phoneNumber;
    _currentUser = MockUser(uid: uid, email: email, phoneNumber: phoneNumber);

    return {
      'success': true,
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);
}

// Mock User for testing without Firebase
class MockUser implements User {
  @override
  final String uid;

  @override
  final String? email;

  final String? _phoneNumber;

  MockUser({required this.uid, this.email, String? phoneNumber})
      : _phoneNumber = phoneNumber;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  // Implement all required User properties
  @override
  bool get emailVerified => true;

  @override
  Future<void> delete() async {}

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock-token';

  @override
  bool get isAnonymous => false;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) {
    throw UnimplementedError();
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<User> unlink(String providerId) async {
    return this;
  }

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  List<UserInfo> get providerData => [];

  @override
  List<UserInfo> get providerUserInfo => [];

  @override
  String? get displayName => _phoneNumber;

  @override
  String? get phoneNumber => _phoneNumber;

  @override
  String? get photoURL => null;

  @override
  String? get refreshToken => 'mock-refresh-token';

  @override
  String get tenantId => '';

  @override
  UserMetadata get metadata => UserMetadata(
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch);
}

// Global auth service instance
late AuthService authService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (USE_FIREBASE_AUTH) {
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

        // For development, enable Auth Emulator if needed
        if (USE_AUTH_EMULATOR) {
          try {
            FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
            print("Connected to Auth Emulator at localhost:9099");
          } catch (e) {
            print("Failed to connect to Auth Emulator: $e");
          }
        }
      } else {
        // For mobile platforms
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print("Firebase initialized for mobile successfully");

          // Test Firebase auth to make sure it's working
          try {
            await FirebaseAuth.instance.signInAnonymously();
            print("Firebase Auth connection test successful");
            await FirebaseAuth.instance.signOut(); // Clean up after test
          } catch (authError) {
            print("Firebase Auth connection test failed: $authError");
            throw Exception("Firebase Auth configuration invalid: $authError");
          }
        } catch (e) {
          print("Error initializing Firebase for mobile: $e");
          throw e;
        }
      }
      // Set auth service to use Firebase
      authService = FirebaseAuthService();
      print("Using Firebase Authentication");
    } else {
      // Set auth service to use mock implementation
      authService = MockAuthService();
      print("Using Mock Authentication - no Firebase needed");
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Print stack trace for debugging
    print(StackTrace.current);

    // Fall back to mock auth if Firebase init fails
    authService = MockAuthService();
    print("Falling back to Mock Authentication due to error");
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
      home: const AuthenticationWrapper(),
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
