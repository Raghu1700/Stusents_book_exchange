import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:rive_animation/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/screens/home/home_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rive_animation/main.dart' show authService;

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  String _errorMessage = '';
  late SMITrigger error;
  late SMITrigger success;
  late SMITrigger reset;

  late SMITrigger confetti;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);

    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  Future<void> signIn(BuildContext context) async {
    // First check if form is valid
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed");

      // Safely trigger error animation
      try {
        error.fire();
      } catch (e) {
        print("Animation error: $e");
      }

      setState(() {
        _errorMessage = 'Please fix the errors above';
        isShowLoading = false;
      });
      return;
    }

    // Set loading state
    setState(() {
      isShowLoading = true;
      _errorMessage = '';
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      print("Attempting login with: $email");

      // Use the auth service instead of direct Firebase calls
      final result = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result['success']) {
        print("Login successful: ${result['uid']}");

        // Safely trigger success animation
        try {
          success.fire();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print("Animation error: $e");
        }

        setState(() {
          isShowLoading = false;
        });

        // Navigate to home screen
        if (!mounted) return;

        // Safely trigger confetti animation
        try {
          confetti.fire();
        } catch (e) {
          print("Animation error: $e");
        }

        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pop(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      } else {
        print("Login failed: ${result['message']}");

        // Safely trigger error animation
        try {
          error.fire();
        } catch (animError) {
          print("Animation error: $animError");
        }

        setState(() {
          _errorMessage = result['message'] ?? 'Login failed';
          isShowLoading = false;
        });
      }
    } catch (e) {
      print("Error during sign in: $e");

      // Safely trigger error animation
      try {
        error.fire();
      } catch (animError) {
        print("Animation error: $animError");
      }

      setState(() {
        _errorMessage = 'An unexpected error occurred';
        isShowLoading = false;
      });
    }
  }

  String _getMessageFromErrorCode(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "Please enter a valid email address.";
      case "user-disabled":
        return "This account has been disabled.";
      case "user-not-found":
        return "No account found with this email.";
      case "wrong-password":
        return "Incorrect password. Please try again.";
      case "too-many-requests":
        return "Too many attempts. Try again later.";
      case "network-request-failed":
        return "Network error. Check your internet connection.";
      case "operation-not-allowed":
        return "Sign-in with this method is not allowed.";
      default:
        return "Sign-in failed: $errorCode";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Email",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
              ),
              const Text(
                "Password",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: isShowLoading ? null : () => signIn(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AF1),
                    minimumSize: const Size(double.infinity, 56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Colors.white,
                  ),
                  label: const Text("Sign In"),
                ),
              ),
            ],
          ),
        ),
        isShowLoading
            ? CustomPositioned(
                child: RiveAnimation.asset(
                  'assets/RiveAssets/check.riv',
                  fit: BoxFit.cover,
                  onInit: (artboard) {
                    try {
                      _onCheckRiveInit(artboard);
                    } catch (e) {
                      print("Error initializing check animation: $e");
                    }
                  },
                ),
              )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
                scale: 6,
                child: RiveAnimation.asset(
                  "assets/RiveAssets/confetti.riv",
                  onInit: (artboard) {
                    try {
                      _onConfettiRiveInit(artboard);
                    } catch (e) {
                      print("Error initializing confetti animation: $e");
                    }
                  },
                  fit: BoxFit.cover,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
