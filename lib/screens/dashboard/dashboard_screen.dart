import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/localization_provider.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizationProvider.translate('dashboard'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                radius: 18,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(context, localizationProvider.translate('newBill'), Icons.add_shopping_cart, Colors.green, '/pos'),
          _buildDashboardCard(context, localizationProvider.translate('products'), Icons.inventory, Colors.orange, '/products'),
          _buildDashboardCard(context, localizationProvider.translate('customers'), Icons.people, Colors.blue, '/customers'),
          _buildDashboardCard(context, 'Credit Management', Icons.credit_card, Colors.red, '/credit'),
          _buildDashboardCard(context, localizationProvider.translate('salesHistory'), Icons.history, Colors.purple, '/sales'),
          _buildDashboardCard(context, 'Categories', Icons.category, Colors.indigo, '/categories'),
          _buildDashboardCard(context, 'Stock Inventory', Icons.inventory_2_outlined, Colors.brown, '/inventory'),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, String? route) {
    return InkWell(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
