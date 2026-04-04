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

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('stockInventory')),
        actions: [
          IconButton(
            icon: Icon(_sortBySales ? Icons.star : Icons.star_border),
            tooltip: 'Sort by Best Seller',
            onPressed: () => setState(() => _sortBySales = !_sortBySales),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
            
            // Category filter logic
            final productCatId = product['category'] is Map 
                ? product['category']['_id'] 
                : product['category'];
            final matchesCategory = _selectedCategoryId == null || productCatId == _selectedCategoryId;

            return matchesSearch && (!_showLowStockOnly || isLowStock) && matchesCategory;
          }).toList();

          // Calculate dynamic high-seller status for the current list
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search stock...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              
              // Category Filter Button (Searchable Bottom Sheet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => _showCategorySelector(context, categoryProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined, color: Colors.deepPurple[400]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategoryId == null 
                                ? 'All Categories' 
                                : categoryProvider.categories.firstWhere((c) => c['_id'] == _selectedCategoryId)['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_selectedCategoryId != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _selectedCategoryId = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                     FilterChip(
                      label: const Text('All Products'),
                      selected: !_showLowStockOnly,
                      onSelected: (selected) => setState(() => _showLowStockOnly = false),
                      selectedColor: Colors.deepPurple[100],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Low Stock'),
                      selected: _showLowStockOnly,
                      onSelected: (selected) => setState(() => _showLowStockOnly = true),
                      selectedColor: Colors.red[100],
                      labelStyle: TextStyle(color: _showLowStockOnly ? Colors.red[900] : Colors.black87),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No matching stock found.'))
                    : ListView.builder(
                        itemCount: products.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final quantity = (product['quantity'] ?? 0).toDouble();
                          final unit = product['unit'] ?? 'Units';
                          final salesCount = (product['salesCount'] ?? 0).toDouble();
                          final isLow = quantity < 5;
                          // Dynamic best seller: item with most sales in this category
                          final isBestSellerInCurrentView = salesCount > 0 && salesCount == maxSales;
                          
                          final categoryName = product['category'] is Map 
                              ? product['category']['name'] 
                              : 'Uncategorized';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isLow ? Colors.red[200]! : Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isLow ? Colors.red[50] : (isBestSellerInCurrentView ? Colors.amber[50] : Colors.deepPurple[50]),
                                child: Icon(
                                  isBestSellerInCurrentView ? Icons.whatshot : Icons.inventory_2_outlined,
                                  color: isLow ? Colors.red : (isBestSellerInCurrentView ? Colors.orange[700] : Colors.deepPurple),
                                ),
                              ),
                              title: Text(
                                product['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$categoryName ',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    if (isBestSellerInCurrentView)
                                      const TextSpan(
                                        text: '🔥 BEST SELLER IN THIS CATEGORY\n',
                                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                      )
                                    else if (salesCount > 0)
                                      TextSpan(
                                        text: '($salesCount Sold)\n',
                                        style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                                      )
                                    else
                                      const TextSpan(text: '\n'),
                                    TextSpan(
                                      text: isLow ? 'LOW STOCK ALERT' : 'Available in stock',
                                      style: TextStyle(
                                        color: isLow ? Colors.red : Colors.green[700], 
                                        fontSize: 11, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    quantity.toStringAsFixed(unit == 'Units' ? 0 : 3),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isLow ? Colors.red : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    unit,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
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

  void _showCategorySelector(BuildContext context, CategoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        String sheetSearch = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = provider.categories.where((c) =>
                c['name'].toString().toLowerCase().contains(sheetSearch.toLowerCase())).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Text('Select Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Category...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setSheetState(() => sheetSearch = v),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        return ListTile(
                          leading: const Icon(Icons.folder_open),
                          title: Text(cat['name']),
                          selected: _selectedCategoryId == cat['_id'],
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
