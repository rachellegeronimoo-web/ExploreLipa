
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignIn = true;
  bool obscurePassword = true;
  bool isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // FIREBASE AUTHENTICATION
  Future<void> authenticate() async {
    debugPrint('EXPLORE LIPA: FIREBASE AUTHENTICATION BUTTON CLICKED');

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please complete all required fields.');
      return;
    }

    if (!isSignIn && name.isEmpty) {
      showMessage('Please enter your full name.');
      return;
    }

    if (!isSignIn && password.length < 6) {
      showMessage('Password must contain at least 6 characters.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isSignIn) {
        debugPrint('EXPLORE LIPA: Signing in...');

        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('EXPLORE LIPA: SIGN IN SUCCESSFUL');

        showMessage('Welcome back to Explore Lipa!');
      } else {
        debugPrint('EXPLORE LIPA: Creating account...');

        final credential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user?.updateDisplayName(name);

        debugPrint('EXPLORE LIPA: ACCOUNT CREATED SUCCESSFULLY');
        debugPrint('EXPLORE LIPA: USER ID: ${credential.user?.uid}');

        showMessage('Your Explore Lipa account was created!');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE ERROR CODE: ${e.code}');
      debugPrint('FIREBASE ERROR MESSAGE: ${e.message}');

      showMessage(getErrorMessage(e.code));
    } catch (e) {
      debugPrint('GENERAL AUTHENTICATION ERROR: $e');

      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ERROR MESSAGES
  String getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Please choose a stronger password.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled in Firebase.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return 'Authentication failed: $code';
    }
  }

  // DISPLAY MESSAGE
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.travel_explore,
                    size: 55,
                    color: AppColors.forest,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'EXPLORE LIPA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Discover the beauty of Lipa City',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 38),

                  // SIGN IN / SIGN UP TABS
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.sage,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab('Sign In', true),
                        ),
                        Expanded(
                          child: _buildTab('Sign Up', false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // FULL NAME
                  if (!isSignIn) ...[
                    _buildLabel('Full Name'),

                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],

                  // EMAIL
                  _buildLabel('Email Address'),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // PASSWORD
                  _buildLabel('Password'),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // AUTHENTICATION BUTTON
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : authenticate,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              isSignIn
                                  ? 'SIGN IN'
                                  : 'CREATE ACCOUNT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    isSignIn
                        ? "Don't have an account yet?"
                        : 'Already have an account?',
                    textAlign: TextAlign.center,
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = !isSignIn;
                      });
                    },
                    child: Text(
                      isSignIn
                          ? 'Create an Account'
                          : 'Sign In Instead',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAB DESIGN
  Widget _buildTab(String label, bool signInTab) {
    final selected = isSignIn == signInTab;

    return GestureDetector(
      onTap: () {
        setState(() {
          isSignIn = signInTab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? AppColors.forest
                : AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // FIELD LABELS
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
