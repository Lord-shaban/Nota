import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// App Drawer - Sidebar Navigation
/// Provides quick access to different sections of the app
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? 'Guest';
    final userEmail = user?.email ?? 'No email';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(userEmail),
          ),

          // Home
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.task_alt_outlined),
            title: const Text('Tasks'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Tasks view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tasks view coming soon!')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Expenses view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expenses view coming soon!')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Appointments'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Appointments view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointments view coming soon!')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.format_quote_outlined),
            title: const Text('Quotes'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to Quotes view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quotes view coming soon!')),
              );
            },
          ),

          const Divider(),

          // Settings & About
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await _showLogoutConfirmation(context);
              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Nota',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.note, size: 48),
      children: [
        const Text(
          'AI-powered Notes & Diary App\n\n'
          'Organize your thoughts, tasks, and expenses with the help of AI.',
        ),
      ],
    );
  }

  /// Show logout confirmation dialog
  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
