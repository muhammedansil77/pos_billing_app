import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'billing/sales_history_screen.dart';
import 'customers/customer_list_screen.dart';
import 'products/product_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SalesHistoryScreen(),
    const CustomerListScreen(),
    const ProductListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF16A34A);
    const Color unselectedGrey = Color(0xFF9CA3AF);
    const Color bgColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/pos'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_shopping_cart, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left Side Items
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', primaryGreen, unselectedGrey),
            _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart, 'Reports', primaryGreen, unselectedGrey),
            
            const SizedBox(width: 48), // Space for FAB
            
            // Right Side Items
            _buildNavItem(2, Icons.people_outline, Icons.people, 'Customers', primaryGreen, unselectedGrey),
            _buildNavItem(3, Icons.inventory_2_outlined, Icons.inventory_2, 'Products', primaryGreen, unselectedGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, Color selectedColor, Color unselectedColor) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withAlpha(25) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
