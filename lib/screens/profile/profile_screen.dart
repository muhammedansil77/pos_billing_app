import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localization = Provider.of<LocalizationProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('profile')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?['name'] ?? 'Guest',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (user != null)
              Text(
                user['email'] ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                user?['role']?.toUpperCase() ?? 'USER',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.deepPurple,
            ),
            const SizedBox(height: 32),
            _profileItem(
              context,
              icon: Icons.settings_outlined,
              title: localization.translate('settings'),
              onTap: () {},
            ),
            _profileItem(
              context,
              icon: Icons.language_outlined,
              title: localization.translate('language'),
              onTap: () {
                 _showLanguageDialog(context, localization);
              },
            ),
            _profileItem(
              context,
              icon: Icons.help_outline,
              title: localization.translate('help_support'),
              onTap: () {},
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  authProvider.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout),
                label: Text(localization.translate('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.red[100]!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
  void _showLanguageDialog(BuildContext context, LocalizationProvider localization) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...localization.languageNames.entries.map((entry) {
                final isSelected = localization.currentLanguage == entry.key;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? Colors.deepPurple : Colors.grey[200],
                    child: Text(entry.key.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                  ),
                  title: Text(entry.value),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
                  onTap: () {
                    localization.setLanguage(entry.key);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
