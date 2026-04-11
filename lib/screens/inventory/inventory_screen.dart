import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/localization_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  bool _sortBySales = false;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localization.translate('stockInventory'),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: Icon(_sortBySales ? Icons.auto_graph_rounded : Icons.trending_up_rounded, color: _sortBySales ? colorScheme.primary : null),
            tooltip: 'Sort by Best Seller',
            onPressed: () => setState(() => _sortBySales = !_sortBySales),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ProductProvider>().fetchProducts(),
          ),
        ],
      ),
      body: Consumer2<ProductProvider, CategoryProvider>(
        builder: (context, productProvider, categoryProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = productProvider.products.where((product) {
            final name = product['name'].toString().toLowerCase();
            final matchesSearch = name.contains(_searchQuery.toLowerCase());
            final isLowStock = (product['quantity'] ?? 0) < 5;
            
            final productCatId = product['category'] is Map 
                ? product['category']['_id'] 
                : product['category'];
            final matchesCategory = _selectedCategoryId == null || productCatId == _selectedCategoryId;

            return matchesSearch && (!_showLowStockOnly || isLowStock) && matchesCategory;
          }).toList();

          double maxSales = 0;
          if (products.isNotEmpty) {
            maxSales = products
                .map((p) => (p['salesCount'] ?? 0).toDouble())
                .reduce((value, element) => value > element ? value : element);
          }

          if (_sortBySales) {
            products.sort((a, b) => (b['salesCount'] ?? 0).compareTo(a['salesCount'] ?? 0));
          }

          return Column(
            children: [
              Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stock...',
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary.withOpacity(0.7)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _showCategorySelector(context, categoryProvider),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategoryId == null 
                                    ? 'All Categories' 
                                    : categoryProvider.categories.firstWhere((c) => c['_id'] == _selectedCategoryId)['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (_selectedCategoryId != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setState(() => _selectedCategoryId = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            const Icon(Icons.keyboard_arrow_down_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _inventoryFilterChip('All Products', !_showLowStockOnly, () => setState(() => _showLowStockOnly = false)),
                        const SizedBox(width: 12),
                        _inventoryFilterChip('Low Stock', _showLowStockOnly, () => setState(() => _showLowStockOnly = true), isAlert: true),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            const Text('No matching stock found.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: products.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final quantity = (product['quantity'] ?? 0).toDouble();
                          final unit = product['unit'] ?? 'Units';
                          final salesCount = (product['salesCount'] ?? 0).toDouble();
                          final isLow = quantity < 5;
                          final isBestSellerInCurrentView = salesCount > 0 && salesCount == maxSales;
                          final categoryName = product['category'] is Map ? product['category']['name'] : 'Uncategorized';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLow ? const Color(0xFFEF4444).withOpacity(0.1) : (isBestSellerInCurrentView ? const Color(0xFFF59E0B).withOpacity(0.1) : colorScheme.primary.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isBestSellerInCurrentView ? Icons.workspace_premium_rounded : Icons.inventory_2_rounded,
                                    color: isLow ? const Color(0xFFEF4444) : (isBestSellerInCurrentView ? const Color(0xFFD97706) : colorScheme.primary),
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  product['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      categoryName,
                                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _statusTag(
                                          isLow ? 'LOW STOCK' : 'AVAILABLE', 
                                          isLow ? const Color(0xFFEF4444) : const Color(0xFF10B981)
                                        ),
                                        if (isBestSellerInCurrentView) ...[
                                          const SizedBox(width: 6),
                                          _statusTag('BEST SELLER', const Color(0xFFF59E0B)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      quantity.toStringAsFixed(unit == 'Units' ? 0 : 3),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: isLow ? const Color(0xFFEF4444) : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      unit,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _inventoryFilterChip(String label, bool isSelected, VoidCallback onSelected, {bool isAlert = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = isAlert ? const Color(0xFFEF4444) : colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  void _showCategorySelector(BuildContext context, CategoryProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String sheetSearch = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = provider.categories.where((c) =>
                c['name'].toString().toLowerCase().contains(sheetSearch.toLowerCase())).toList();

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const Text('Select Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Category...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    onChanged: (v) => setSheetState(() => sheetSearch = v),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.only(top: 8),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        final isSelected = _selectedCategoryId == cat['_id'];
                        return ListTile(
                          leading: Icon(Icons.folder_rounded, color: isSelected ? colorScheme.primary : Colors.grey.shade400),
                          title: Text(cat['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold)),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: colorScheme.primary) : null,
                          onTap: () {
                            setState(() => _selectedCategoryId = cat['_id']);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
