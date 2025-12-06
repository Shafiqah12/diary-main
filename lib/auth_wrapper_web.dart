// lib/auth_wrapper_web.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase User
import 'auth_service.dart'; // Import your AuthService
import 'homepage.dart'; // Your main content page (e.g., lib/homepage.dart)
import 'login_page.dart'; // Your combined login page (e.g., lib/login_page.dart)

/// AuthWrapperWeb listens to Firebase authentication state changes
/// and conditionally renders HomePage or LoginPage.
/// This widget is now StatelessWidget as its state is managed by the Firebase stream.
class AuthWrapperWeb extends StatelessWidget {
  const AuthWrapperWeb({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the AuthService instance.
    // In a larger app, you might use a state management solution like Provider
    // to make AuthService globally accessible.
    final AuthService _auth = AuthService();

    // StreamBuilder listens to the authentication state changes from AuthService.
    // It rebuilds its child widget whenever the user's login status changes.
    return StreamBuilder<User?>(
      stream: _auth.user, // The stream from AuthService that emits User or null
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        // --- Handle Connection States ---

        // 1. Waiting state: Show a loading indicator while checking auth state.
        // This is important for the initial check when the app starts up.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(), // Show a loading spinner
            ),
          );
        }

        // 2. Error state: If there's an error with the stream itself.
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'), // Display stream error
            ),
          );
        }

        // --- Handle Authentication State ---

        // If snapshot.hasData is true AND snapshot.data is not null,
        // it means a User object is available, indicating the user is logged in.
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, show the HomePage.
          return const HomePage();
        } else {
          // User is not logged in (snapshot.data is null), show the LoginPage.
          // The LoginPage no longer takes an 'onLoginSuccess' callback,
          // as the StreamBuilder directly reacts to Firebase authentication state.
          return const LoginPage();
        }
      },
    );
  }
}


