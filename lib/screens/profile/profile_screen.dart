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
    final colorScheme = Theme.of(context).colorScheme;
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localization.translate('profile'),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withOpacity(0.1), width: 4),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person_rounded, size: 50, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              user?['name'] ?? 'Guest User',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            if (user != null)
              Text(
                user['email'] ?? '',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?['role']?.toUpperCase() ?? 'USER',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 48),
            _profileItem(
              context,
              icon: Icons.settings_rounded,
              title: localization.translate('settings'),
              onTap: () {},
            ),
            _profileItem(
              context,
              icon: Icons.language_rounded,
              title: localization.translate('language'),
              onTap: () {
                 _showLanguageDialog(context, localization);
              },
            ),
            _profileItem(
              context,
              icon: Icons.help_center_rounded,
              title: localization.translate('help_support'),
              onTap: () {},
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  authProvider.logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  localization.translate('logout'),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.3)),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocalizationProvider localization) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              ...localization.languageNames.entries.map((entry) {
                final isSelected = localization.currentLanguage == entry.key;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
                    child: Text(entry.key.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : colorScheme.primary, fontWeight: FontWeight.w900)),
                  ),
                  title: Text(entry.value, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold)),
                  trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colorScheme.primary) : null,
                  onTap: () {
                    localization.setLanguage(entry.key);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
