import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive_animation/screens/home/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:rive_animation/main.dart' show authService;
import 'package:rive_animation/services/payment_service.dart';
import 'package:rive_animation/model/user_payment_settings.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
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
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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

  Future<void> signUp(BuildContext context) async {
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
      String phone = _phoneController.text.trim();

      print("Attempting registration with: $email");

      // Use the auth service instead of direct Firebase calls
      final result = await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        phoneNumber: phone,
      );

      if (result['success']) {
        print("Registration successful: ${result['uid']}");

        // Store payment settings
        try {
          final paymentSettings = UserPaymentSettings(
            phoneNumber: phone,
            upiId: '${email.split('@')[0]}@upi', // Generate a default UPI ID
            bankDetails: '', // Empty initially
          );

          await PaymentService().updatePaymentSettings(paymentSettings);
        } catch (e) {
          print("Error saving payment settings: $e");
          // Continue anyway
        }

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
        print("Registration failed: ${result['message']}");

        // Safely trigger error animation
        try {
          error.fire();
        } catch (animError) {
          print("Animation error: $animError");
        }

        setState(() {
          _errorMessage = result['message'] ?? 'Registration failed';
          isShowLoading = false;
        });
      }
    } catch (e) {
      print("Error during sign up: $e");

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
      case "email-already-in-use":
        return "This email is already registered. Try signing in instead.";
      case "invalid-email":
        return "Please enter a valid email address.";
      case "operation-not-allowed":
        return "Email/password registration is not enabled.";
      case "weak-password":
        return "Your password is too weak. Use at least 6 characters.";
      case "network-request-failed":
        return "Network error. Check your internet connection.";
      case "too-many-requests":
        return "Too many attempts. Try again later.";
      default:
        return "Registration failed: $errorCode";
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
                "Phone Number",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Phone number is required";
                    }
                    if (value.length < 10) {
                      return "Please enter a valid phone number";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
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
              const Text(
                "Confirm Password",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
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
                  onPressed: isShowLoading ? null : () => signUp(context),
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
                  label: const Text("Sign Up"),
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
                  fit: BoxFit.cover,
                  onInit: (artboard) {
                    try {
                      _onConfettiRiveInit(artboard);
                    } catch (e) {
                      print("Error initializing confetti animation: $e");
                    }
                  },
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
