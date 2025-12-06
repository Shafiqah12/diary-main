// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // This import will now be used!
import 'homepage.dart'; // Your main content page (e.g., where the diary entries are)
import 'login_screen.dart'; // The Firebase login/registration screen for mobile

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to changes in the Firebase authentication state.
    // When a user signs in or out, this widget will rebuild accordingly.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is waiting (e.g., Firebase is initializing or checking state)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(), // Show a loading spinner while checking auth state
            ),
          );
        }

        // If there is data in the snapshot, it means a User object is present,
        // indicating a user is currently signed in to Firebase.
        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, navigate to the HomePage.
          return const HomePage();
        } else {
          // No user is signed in (snapshot.data is null).
          // Navigate to the LoginScreen.
          return const LoginScreen();
        }
      },
    );
  }
}
