// lib/login_page.dart - Combined Firebase Email/Password and Biometric Login
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:local_auth/local_auth.dart'; // For biometric authentication
import 'auth_service.dart'; // Your custom authentication service

/// LoginPage handles user sign-in and registration using Firebase Email/Password.
/// It also provides an option for biometric authentication (primarily for mobile).
class LoginPage extends StatefulWidget {
  // The onLoginSuccess callback is no longer needed here because AuthWrapperWeb
  // now listens directly to Firebase authentication state changes.
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Instantiate your AuthService to interact with Firebase Auth
  final AuthService _authService = AuthService();
  // Instantiate LocalAuthentication for biometric checks
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Text controllers for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // GlobalKey for the Form widget to enable form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variable to display error messages to the user
  String? _errorMessage;
  // State variable to toggle password visibility
  bool _isPasswordObscure = true;

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles user sign-in with email and password using AuthService.
  Future<void> _signInWithEmailAndPassword() async {
    // Validate the form fields before proceeding
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null; // Clear any previous error messages
      });
      try {
        // Call the signInWithEmailAndPassword method from AuthService
        UserCredential? userCredential = await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (userCredential != null) {
          // If sign-in is successful, the AuthWrapperWeb's StreamBuilder will
          // automatically detect the change in FirebaseAuth.instance.authStateChanges()
          // and navigate to the HomePage. No explicit Navigator.push here.
          print('User signed in: ${userCredential.user?.email}');
          // Optionally show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in successful!')),
          );
        } else {
          // If userCredential is null, it means an error occurred and was handled
          // within AuthService, likely printing to console.
          // We can set a generic message or refine based on AuthService's return.
          setState(() {
            _errorMessage = 'Sign in failed. Please check your credentials.';
          });
        }
      } on FirebaseAuthException catch (e) {
        // Catch specific Firebase authentication errors
        setState(() {
          _errorMessage = e.message; // Display the error message from Firebase
        });
        print("Login Error: ${e.code} - ${e.message}");
      } catch (e) {
        // Catch any other unexpected errors
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        print("Unexpected Login Error: $e");
      }
    }
  }

  /// Handles user registration with email and password using AuthService.
  Future<void> _registerWithEmailAndPassword() async {
    // Validate the form fields before proceeding
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null; // Clear any previous error messages
      });
      try {
        // Call the signUpWithEmailAndPassword method from AuthService
        UserCredential? userCredential = await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (userCredential != null) {
          // If registration is successful, the AuthWrapperWeb will detect the new user
          // and navigate to HomePage.
          print('User registered: ${userCredential.user?.email}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! You are now logged in.')),
          );
        } else {
          // If userCredential is null, it means an error occurred and was handled
          // within AuthService.
          setState(() {
            _errorMessage = 'Registration failed. Please try a different email or stronger password.';
          });
        }
      } on FirebaseAuthException catch (e) {
        // Catch specific Firebase authentication errors during registration
        setState(() {
          _errorMessage = e.message;
        });
        print("Registration Error: ${e.code} - ${e.message}");
      } catch (e) {
        // Catch any other unexpected errors
        setState(() {
          _errorMessage = 'An unexpected error occurred during registration. Please try again.';
        });
        print("Unexpected Registration Error: $e");
      }
    }
  }

  /// Handles biometric authentication.
  /// Note: Biometric authentication is primarily for mobile devices.
  /// On web, this might not be fully supported or behave as expected
  /// unless specific WebAuthn capabilities are implemented.
  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _errorMessage = null; // Clear any previous error messages
    });

    // Check if biometrics are available on the device
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    List<BiometricType> availableBiometrics = [];
    if (canCheckBiometrics) {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    }

    if (!canCheckBiometrics || availableBiometrics.isEmpty) {
      setState(() {
        _errorMessage = 'No biometrics available or configured on this device.';
      });
      return;
    }

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to log in with biometrics',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep the authentication dialog visible until dismissed
          biometricOnly: false, // Allow device passcode if biometrics are not enrolled
        ),
      );
    } on Exception catch (e) {
      // Handle exceptions during biometric authentication (e.g., user cancels)
      setState(() {
        _errorMessage = 'Biometric authentication failed: ${e.toString()}';
      });
      print("Biometric Auth Exception: $e");
    }

    if (authenticated) {
      // IMPORTANT: Successful biometric authentication *by itself* does not
      // automatically log a user into Firebase. You would typically need to:
      // 1. Have a Firebase user already linked to this device's biometrics.
      // 2. Or, if the app allows it, sign in an anonymous Firebase user after biometric success:
      //    await _authService.signInAnonymously(); // You would need to add this to AuthService
      // 3. Or, if you have a secure way to identify the user after biometric success (e.g., a stored local ID
      //    that corresponds to a Firebase UID), you could then use a custom token generated by your backend
      //    to sign them into Firebase.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication successful!')),
      );
      // For a real-world app, you'd integrate this with Firebase sign-in
      // (e.g., by signing in an anonymous user or using a custom token).
      // For now, this just indicates local biometric success.
    } else {
      setState(() {
        _errorMessage = 'Biometric authentication failed or canceled.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shafiqah's Diary"),
        backgroundColor: Colors.teal, // Consistent color with your original LoginPage
        elevation: 0, // Remove shadow for a cleaner look
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0), // Generous padding
          child: Form(
            key: _formKey, // Assign the form key for validation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Welcome to Shafiqah's Diary",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800], // Darker teal for emphasis
                      ),
                ),
                const SizedBox(height: 40), // More vertical space

                // Email Input Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.teal), // Teal icon
                    filled: true,
                    fillColor: Colors.teal.withOpacity(0.05), // Very light teal background
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Input Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscure, // Control visibility
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)), // Rounded corners
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.teal), // Teal icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.teal,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscure = !_isPasswordObscure; // Toggle password visibility
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.teal.withOpacity(0.05), // Very light teal background
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _signInWithEmailAndPassword(), // Allow sign-in on submit
                ),
                const SizedBox(height: 20),

                // Display Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Sign In Button
                ElevatedButton.icon(
                  onPressed: _signInWithEmailAndPassword,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded button
                    ),
                    backgroundColor: Colors.teal, // Use teal from your original LoginPage
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    elevation: 5, // Add a subtle shadow
                  ),
                ),
                const SizedBox(height: 15),

                // Register Button
                OutlinedButton.icon(
                  onPressed: _registerWithEmailAndPassword,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded button
                    ),
                    side: const BorderSide(color: Colors.teal, width: 2), // Teal border
                    foregroundColor: Colors.teal, // Teal text
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),

                // Divider
                const Divider(thickness: 1.5, indent: 20, endIndent: 20, color: Colors.grey),
                const SizedBox(height: 30),

                // Biometric Authentication Button
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint, size: 28), // Larger icon
                  label: const Text('Authenticate with Biometrics'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blueGrey[700], // A distinct, neutral color
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
