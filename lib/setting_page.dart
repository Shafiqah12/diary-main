// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW
import 'theme_provider.dart';
import 'notification_service.dart'; // NEW
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeProvider.appBarColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // PROFILE SECTION
          const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ListTile(
            leading: CircleAvatar(backgroundColor: themeProvider.appBarColor, child: const Icon(Icons.person, color: Colors.white)),
            title: Text(user?.displayName ?? "Set Pen Name"),
            subtitle: Text(user?.email ?? ""),
            trailing: const Icon(Icons.edit),
            onTap: () => _showUpdateNameDialog(context),
          ),
          const Divider(),

          // THEME OPTIONS (Your existing code)
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (isOn) { themeProvider.toggleTheme(isOn); },
          ),
          ListTile(
            title: const Text('App Bar Color'),
            trailing: CircleAvatar(backgroundColor: themeProvider.appBarColor, radius: 15),
            onTap: () async {
              // ... Keep your existing color picker showDialog code here ...
            },
          ),
          const Divider(),

          // NOTIFICATION SECTION
          const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text("Test Reminder"),
            subtitle: const Text("Tap to see if notifications work"),
            onTap: () {
              NotificationService().showInstantNotification(
                "Time to Write! ✍️", 
                "Don't break your streak! How was your day?",
              );
            },
          ),

          const Divider(),
ListTile(
  leading: const Icon(Icons.notifications_active),
  title: const Text('Test Notification'),
  subtitle: const Text('Send an instant reminder'),
  onTap: () async {
    // This sends a notification immediately
    await NotificationService.scheduleDailyReminder(); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily reminder scheduled for 8:00 PM!')),
    );
  },
),
        ],
      ),
    );
  }

  void _showUpdateNameDialog(BuildContext context) {
    final controller = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Pen Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter your name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.updateDisplayName(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
            }, 
            child: const Text("Save")
          ),
        ],
      ),
    );
  }
}