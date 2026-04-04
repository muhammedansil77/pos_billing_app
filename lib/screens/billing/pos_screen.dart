import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/localization_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import 'barcode_scanner_screen.dart';
import '../../utils/snackbar_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final ApiService _apiService = ApiService();
  late MobileScannerController _scannerController;
  bool _showCamera = true;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }


  void _addError(String message) {
    if (message.startsWith('STOCK_LIMIT|')) {
      final parts = message.split('|');
      final loc = Provider.of<LocalizationProvider>(context, listen: false);
      SnackbarUtils.showError(context, loc.translateStockError(parts[1], parts[2]));
    } else {
      SnackbarUtils.showError(context, message);
    }
  }

  void _addSuccess(String message) {
    SnackbarUtils.showSuccess(context, message);
  }

  Future<void> _scanProduct() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (barcode != null && barcode.isNotEmpty) {
       _processScannedBarcode(barcode);
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      String? barcode = barcodes.first.displayValue;
      if (barcode != null && barcode.isNotEmpty) {
        setState(() => _isProcessingScan = true);
        await _processScannedBarcode(barcode);
        // Add a cooldown to prevent rapid multi-scans of same item
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessingScan = false);
        });
      }
    }
  }

  Future<void> _processScannedBarcode(String barcode) async {
    try {
      final product = await _apiService.getProductByBarcode(barcode);
      
      double quantity = 1.0;
      if (product['unit'] == 'kg' || product['unit'] == 'Grams') {
        final double? weight = await _showWeightDialog(product['name'], product['unit']);
        if (weight == null || weight <= 0) return;
        quantity = weight;
      }

      if (mounted) {
        try {
          context.read<BillingProvider>().addItem(product, quantity);
          _addSuccess('Added: ${product['name']}');
        } catch (e) {
            _addError(e.toString());
        }
      }
    } catch (e) {
      _addError(e.toString());
    }
  }

  Future<double?> _showWeightDialog(String productName, String productUnit) async {
    final TextEditingController weightController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    String unit = (productUnit == 'kg' || productUnit == 'Grams') ? productUnit : 'kg';
    bool isUnitBased = productUnit == 'Units';

    // Requesting focus after the dialog is built to ensure keyboard pop-up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    return await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isUnitBased ? 'Enter Quantity: $productName' : 'Enter Weight: $productName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    focusNode: focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(decimal: !isUnitBased),
                    decoration: InputDecoration(
                      labelText: isUnitBased ? 'Quantity' : 'Weight',
                      border: const OutlineInputBorder(),
                      suffixText: isUnitBased ? 'Units' : unit,
                    ),
                  ),
                  if (!isUnitBased) ...[
                    const SizedBox(height: 16),
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      isSelected: [unit == 'kg', unit == 'grams' || unit == 'Grams'],
                      onPressed: (index) {
                        setDialogState(() => unit = index == 0 ? 'kg' : 'grams');
                      },
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('KG')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Grams')),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    focusNode.dispose();
                    Navigator.pop(context);
                  }, 
                  child: const Text('CANCEL')
                ),
                ElevatedButton(
                  onPressed: () {
                    final String valStr = weightController.text;
                    if (valStr.isEmpty) return;
                    
                    double val = double.tryParse(valStr) ?? 0;
                    if (!isUnitBased && (unit == 'grams' || unit == 'Grams')) val /= 1000;
                    
                    if (isUnitBased && valStr.contains('.')) {
                       final localization = Provider.of<LocalizationProvider>(context, listen: false);
                       SnackbarUtils.showError(context, localization.translate('noDecimalItems'));
                       return;
                    }
                    focusNode.dispose();
                    Navigator.pop(context, val > 0 ? val : null);
                  },
                  child: const Text('ADD TO BILL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizationProvider.translate('newBill')),
        actions: [
          IconButton(
            icon: Icon(_showCamera ? Icons.videocam_off_outlined : Icons.videocam_outlined),
            tooltip: _showCamera ? 'Hide Scanner' : 'Show Scanner',
            onPressed: () => setState(() => _showCamera = !_showCamera),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanProduct,
          ),
        ],
      ),
      body: Consumer<BillingProvider>(
        builder: (context, billing, child) {
          if (billing.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (billing.paymentMode == 'Credit') _customerSelectionHeader(billing),
              
              if (_showCamera)
                Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple, width: 2),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onBarcodeDetected,
                        // Removed scanWindow as it might be too restrictive in some versions
                      ),
                      // Scanner Overlay
                      Container(
                        decoration: BoxDecoration(
                          color: _isProcessingScan ? Colors.green.withAlpha(50) : Colors.transparent,
                        ),
                        child: Center(
                          child: Container(
                            width: 250,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isProcessingScan ? Colors.green : Colors.white70, 
                                width: 2
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isProcessingScan 
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : null,
                          ),
                        ),
                      ),
                      // Torch Toggle Button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.flashlight_on, color: Colors.white, size: 20),
                            onPressed: () => _scannerController.toggleTorch(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: billing.billingItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              localizationProvider.translate('noItemsAlert'),
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: billing.billingItems.length,
                        itemBuilder: (context, index) {
                          final item = billing.billingItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${item['sellingPrice'] ?? item['price']} x ${item['billQuantity']} ${item['unit'] ?? ''}',
                                  ),
                                  Text(
                                    'Stock: ${item['quantity'] ?? 0} ${item['unit'] ?? ''}',
                                    style: TextStyle(
                                      color: (item['quantity'] ?? 0) < 5 ? Colors.red : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                    onPressed: () => billing.updateQuantity(index, -1),
                                  ),
                                  Text(
                                    item['billQuantity'] is double 
                                      ? (item['billQuantity'] as double).toStringAsFixed(item['unit'] == 'Units' ? 0 : 3)
                                      : '${item['billQuantity']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                    onPressed: () => billing.updateQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              _bottomSummary(billing),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomSummary(BillingProvider billing) {
    final discountController = TextEditingController(text: billing.discount.toString());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal:', '₹${billing.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Total GST:', '₹${billing.totalGst.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Mode:', style: TextStyle(fontSize: 16)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.money)),
                  ButtonSegment(value: 'Credit', label: Text('Credit'), icon: Icon(Icons.credit_card)),
                ],
                selected: {billing.paymentMode},
                onSelectionChanged: (Set<String> newSelection) {
                  billing.setPaymentMode(newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF16A34A),
                  selectedForegroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (billing.paymentMode == 'Credit' && billing.selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customer:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(
                  billing.selectedCustomer!['name'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount:', style: TextStyle(fontSize: 16, color: Colors.red)),
              SizedBox(
                width: 100,
                height: 35,
                child: TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (v) {
                    billing.setDiscount(double.tryParse(v) ?? 0.0);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                '₹${billing.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: billing.billingItems.isEmpty ? null : () async {
                try {
                  await billing.checkout();
                  if (mounted) {
                    final loc = Provider.of<LocalizationProvider>(context, listen: false);
                    _addSuccess(billing.editingBillId != null ? 'Bill updated successfully' : loc.translate('billSaved'));
                  }
                } catch (e) {
                  if (e.toString().contains('PLEASE_SELECT_CUSTOMER')) {
                    _addError('Please select a customer for credit billing');
                    _showCustomerSelector();
                  } else {
                    _addError(e.toString());
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                billing.editingBillId != null ? 'UPDATE BILL' : 'CHECKOUT', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const CustomerSelectorSheet(),
    );
  }

  Widget _customerSelectionHeader(BillingProvider billing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: billing.selectedCustomer == null 
          ? Colors.red.withAlpha(20) 
          : Colors.green.withAlpha(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CREDIT CUSTOMER:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: billing.selectedCustomer == null ? Colors.red[700] : Colors.green[700],
                ),
              ),
              const Spacer(),
              if (billing.selectedCustomer != null)
                TextButton.icon(
                  onPressed: () => billing.setSelectedCustomer(null),
                  icon: const Icon(Icons.clear, size: 14),
                  label: const Text('Change', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],
          ),
          InkWell(
            onTap: _showCustomerSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: billing.selectedCustomer == null ? Colors.red : Colors.green.withAlpha(100),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (billing.selectedCustomer == null ? Colors.red : Colors.green).withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    billing.selectedCustomer == null ? Icons.person_add_outlined : Icons.person,
                    color: billing.selectedCustomer == null ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billing.selectedCustomer?['name'] ?? 'SELECT CUSTOMER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: billing.selectedCustomer == null ? Colors.red : Colors.black87,
                          ),
                        ),
                        if (billing.selectedCustomer != null)
                          Text(
                            billing.selectedCustomer!['phone'] ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: billing.selectedCustomer == null ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class CustomerSelectorSheet extends StatefulWidget {
  const CustomerSelectorSheet({super.key});

  @override
  State<CustomerSelectorSheet> createState() => _CustomerSelectorSheetState();
}

class _CustomerSelectorSheetState extends State<CustomerSelectorSheet> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Text('Select Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by Name or Phone...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                
                final filtered = provider.customers.where((c) {
                  final name = (c['name'] ?? '').toString().toLowerCase();
                  final phone = (c['phone'] ?? '').toString();
                  return name.contains(_searchQuery) || phone.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('No customers found.'));

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(customer['name'][0])),
                      title: Text(customer['name']),
                      subtitle: Text(customer['phone']),
                      onTap: () {
                        context.read<BillingProvider>().setSelectedCustomer(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
