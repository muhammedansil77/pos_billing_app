import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/localization_provider.dart';
import '../billing/barcode_scanner_screen.dart';
import '../../utils/snackbar_utils.dart';
import 'dart:math';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _gstController = TextEditingController(text: '0');
  String _selectedUnit = 'kg';
  bool _formIsValid = false;
  
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!['name'] ?? '';
      _wholesalePriceController.text = (widget.product!['wholesalePrice'] ?? 0).toString();
      _sellingPriceController.text = (widget.product!['sellingPrice'] ?? widget.product!['price'] ?? 0).toString();
      _quantityController.text = (widget.product!['quantity'] ?? 0).toString();
      _barcodeController.text = widget.product!['barcode'] ?? '';
      _gstController.text = (widget.product!['gstPercentage'] ?? 0).toString();
      _selectedUnit = widget.product!['unit'] ?? 'kg';
    }
    
    // Initial validation check
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
  }

  void _validateForm() {
    if (_formKey.currentState == null) return;
    
    final isValid = _formKey.currentState!.validate();
    if (_formIsValid != isValid) {
      setState(() {
        _formIsValid = isValid;
      });
    }
  }

  void _scanBarcode() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (barcode != null && barcode.isNotEmpty) {
      _barcodeController.text = barcode;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final Map<String, dynamic> productData = {
          'name': _nameController.text,
          'wholesalePrice': double.parse(_wholesalePriceController.text),
          'sellingPrice': double.parse(_sellingPriceController.text),
          'quantity': double.parse(_quantityController.text),
          'unit': _selectedUnit,
          'barcode': _barcodeController.text,
          'gstPercentage': double.tryParse(_gstController.text) ?? 0.0,
        };

        final productProvider = context.read<ProductProvider>();
        
        if (_isEditing) {
          await productProvider.updateProduct(widget.product!['_id'], productData);
        } else {
          await productProvider.addProduct(productData);
        }

        if (mounted) {
          final loc = Provider.of<LocalizationProvider>(context, listen: false);
          SnackbarUtils.showSuccess(context, _isEditing ? loc.translate('productUpdated') : loc.translate('productCreated'));
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    onChanged: (_) => _validateForm(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Product Name', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Product name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _wholesalePriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _validateForm(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Wholesale Price', 
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wholesale Price is required';
                            final val = double.tryParse(v);
                            if (val == null) return 'Enter a valid number';
                            final selling = double.tryParse(_sellingPriceController.text);
                            if (selling != null && val > selling) return 'Must be less than or equal to selling price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _validateForm(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price', 
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Selling Price is required';
                            final val = double.tryParse(v);
                            if (val == null) return 'Enter a valid number';
                            final wholesale = double.tryParse(_wholesalePriceController.text);
                            if (wholesale != null && val < wholesale) return 'Selling price must be greater than wholesale price';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _validateForm(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid Number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                          items: ['kg', 'Units', 'Grams', 'Litre'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedUnit = v!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _barcodeController,
                    onChanged: (_) => _validateForm(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Barcode Code (Leave empty to auto-generate)', 
                      border: const OutlineInputBorder(), 
                      hintText: 'Ex: 89010300',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Scan Barcode',
                            onPressed: _scanBarcode,
                          ),
                          IconButton(
                            icon: const Icon(Icons.autorenew),
                            tooltip: 'Generate Barcode',
                            onPressed: () {
                              final random = Random();
                              String generated = '';
                              for (int i = 0; i < 12; i++) {
                                generated += random.nextInt(10).toString();
                              }
                              _barcodeController.text = generated;
                              _validateForm();
                            },
                          ),
                        ],
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final products = context.read<ProductProvider>().products;
                        final exists = products.any((p) {
                          if (_isEditing && p['_id'] == widget.product!['_id']) return false;
                          return p['barcode'] == v;
                        });
                        if (exists) return 'Barcode already exists';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _validateForm(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(labelText: 'GST Percentage (%)', border: OutlineInputBorder()),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = double.tryParse(v);
                        if (val == null) return 'Enter a valid number';
                        if (val < 0 || val > 100) return 'GST must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  productProvider.isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _formIsValid ? _saveProduct : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _formIsValid ? Colors.deepPurple : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_isEditing ? 'UPDATE PRODUCT' : 'SAVE PRODUCT', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
