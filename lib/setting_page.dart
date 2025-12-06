// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Make sure this path is correct
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import for color picker

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeProvider.appBarColor, // Use dynamic app bar color
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Dark Mode Switch
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (isOn) {
              themeProvider.toggleTheme(isOn);
            },
          ),
          const Divider(), // Add a visual separator

          // Change App Bar Color Button
          ListTile(
            title: const Text('App Bar Color'),
            trailing: CircleAvatar(
              backgroundColor: themeProvider.appBarColor,
              radius: 15,
            ),
            onTap: () async {
              Color? newColor = await showDialog<Color>(
                context: context,
                builder: (BuildContext context) {
                  Color selectedColor = themeProvider.appBarColor; // Initial color
                  return AlertDialog(
                    title: const Text('Select App Bar Color'),
                    content: SingleChildScrollView(
                      child: BlockPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          selectedColor = color; // Update local variable for picker
                        },
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('CANCEL'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Dismiss without saving
                        },
                      ),
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop(selectedColor); // Return selected color
                        },
                      ),
                    ],
                  );
                },
              );
              if (newColor != null) {
                themeProvider.changeAppBarColor(newColor);
              }
            },
          ),
          // Add more settings options here later
        ],
      ),
    );
  }
}