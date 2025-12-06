// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:local_auth/local_auth.dart'; // Import local_auth for biometrics

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _errorMessage; // To display error messages to the user

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to handle email and password sign-in
  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _errorMessage = null; }); // Clear any previous error messages
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // If sign-in is successful, the AuthWrapper's StreamBuilder will detect
        // the change in FirebaseAuth.instance.authStateChanges() and automatically
        // navigate to the HomePage. No explicit Navigator.push here.
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

  // Function to handle email and password registration
  Future<void> _registerWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _errorMessage = null; }); // Clear any previous error messages
      try {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // If registration is successful, the AuthWrapper will detect the new user
        // and navigate to HomePage.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! You are now logged in.')),
        );
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

  // Function to handle biometric authentication
  Future<void> _authenticateWithBiometrics() async {
    // Check if biometrics are available on the device
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

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
      //    await _auth.signInAnonymously();
      // 3. Or, if you have a secure way to identify the user after biometric success (e.g., a stored local ID
      //    that corresponds to a Firebase UID), you could then use a custom token generated by your backend
      //    to sign them into Firebase.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication successful!')),
      );
      // For this example, if biometrics succeed, we assume the user is "logged in"
      // locally. If you want this to also log them into Firebase, you'll need
      // to implement the Firebase sign-in logic here (e.g., anonymous sign-in,
      // or linking to an existing Firebase account if securely identified).
    } else {
      setState(() {
        _errorMessage = 'Biometric authentication failed or canceled.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding for better spacing
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Shafiqah's Diary",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor, // Use theme primary color
                  ),
                ),
                const SizedBox(height: 40), // More space
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)), // Rounded corners
                    ),
                    prefixIcon: Icon(Icons.email),
                    filled: true, // Add fill color
                    fillColor: Colors.white70, // Light background for text field
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
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)), // Rounded corners
                    ),
                    prefixIcon: Icon(Icons.lock),
                    filled: true, // Add fill color
                    fillColor: Colors.white70, // Light background for text field
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0), // More space below error
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _signInWithEmailAndPassword,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded button
                    ),
                    backgroundColor: Theme.of(context).primaryColor, // Use theme primary color
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15), // More space
                OutlinedButton.icon(
                  onPressed: _registerWithEmailAndPassword,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded button
                    ),
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 2), // Border color
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30), // More space
                const Divider(thickness: 1.5, indent: 20, endIndent: 20), // Thicker divider
                const SizedBox(height: 30), // More space
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
