import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/localization_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizationProvider.translate('dashboard'),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  radius: 18,
                  child: Icon(Icons.person_rounded, color: colorScheme.primary, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildDashboardCard(context, localizationProvider.translate('newBill'), Icons.add_shopping_cart_rounded, const Color(0xFF10B981), '/pos'),
          _buildDashboardCard(context, localizationProvider.translate('products'), Icons.inventory_2_rounded, const Color(0xFFF59E0B), '/products'),
          _buildDashboardCard(context, localizationProvider.translate('customers'), Icons.people_alt_rounded, const Color(0xFF3B82F6), '/customers'),
          _buildDashboardCard(context, 'Credit Management', Icons.payments_rounded, const Color(0xFFEF4444), '/credit'),
          _buildDashboardCard(context, localizationProvider.translate('salesHistory'), Icons.receipt_long_rounded, const Color(0xFF8B5CF6), '/sales'),
          _buildDashboardCard(context, 'Categories', Icons.category_rounded, const Color(0xFF6366F1), '/categories'),
          _buildDashboardCard(context, 'Stock Inventory', Icons.warehouse_rounded, const Color(0xFF78350F), '/inventory'),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, String? route) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        if (route != null) Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
