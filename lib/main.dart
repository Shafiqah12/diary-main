// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_wrapper.dart'; // For mobile (biometric)
import 'auth_wrapper_web.dart'; // For web (password)
import 'theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
// Import your new custom_app_bar
// NEW import
import 'firebase_options.dart'; // Import your Firebase options

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Required to ensure Flutter engine is initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "Shafiqah's Diary",
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.quicksand().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.appBarColor,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.quicksand(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Apply Quicksand to TextTheme for general text consistency
        textTheme: GoogleFonts.quicksandTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.quicksand().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: themeProvider.appBarColor,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.quicksand(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Apply Quicksand to TextTheme for general text consistency
        textTheme: GoogleFonts.quicksandTextTheme(Theme.of(context).textTheme),
      ),
      home: kIsWeb ? const AuthWrapperWeb() : const AuthWrapper(),
    );
  }
}
