import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Store Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('admin@test.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.store, color: Colors.deepPurple, size: 36),
            ),
            decoration: const BoxDecoration(color: Colors.deepPurple),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blueAccent),
            title: Text(localizationProvider.translate('dashboard')),
            selected: currentRoute == '/dashboard',
            onTap: () {
              if (currentRoute != '/dashboard') {
                Navigator.pushReplacementNamed(context, '/dashboard');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
            title: Text(localizationProvider.translate('newBill')),
            selected: currentRoute == '/pos',
            onTap: () {
              if (currentRoute != '/pos') {
                Navigator.pushReplacementNamed(context, '/pos');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.orange),
            title: Text(localizationProvider.translate('products')),
            selected: currentRoute == '/products',
            onTap: () {
              if (currentRoute != '/products') {
                Navigator.pushReplacementNamed(context, '/products');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.indigo),
            title: const Text('Categories'), // I'll use hardcoded for now, but will update localization later if needed
            selected: currentRoute == '/categories',
            onTap: () {
              if (currentRoute != '/categories') {
                Navigator.pushReplacementNamed(context, '/categories');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: Text(localizationProvider.translate('customers')),
            selected: currentRoute == '/customers',
            onTap: () {
              Navigator.pop(context);
              // Navigator.pushReplacementNamed(context, '/customers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: Text(localizationProvider.translate('salesHistory')),
            selected: currentRoute == '/sales',
            onTap: () {
              if (currentRoute != '/sales') {
                Navigator.pushReplacementNamed(context, '/sales');
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Divider(),
          // Language Switcher in Drawer
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizationProvider.translate('changeLanguage')),
            trailing: DropdownButton<String>(
              value: localizationProvider.currentLanguage,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  localizationProvider.setLanguage(newValue);
                }
              },
              items: localizationProvider.languageNames.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(localizationProvider.translate('logout')),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
