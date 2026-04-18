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
                            Icon(Icons.shopping_basket_outlined, size: 84, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              localizationProvider.translate('noItemsAlert'),
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: billing.billingItems.length,
                        itemBuilder: (context, index) {
                          final item = billing.billingItems[index];
                          final sellingPrice = (item['sellingPrice'] ?? item['price'] ?? 0.0);
                          final billQty = item['billQuantity'] ?? 0.0;
                          final itemTotal = sellingPrice * billQty;
                          final isUnit = item['unit'] == 'Units';
                          final isLowStock = (item['quantity'] ?? 0) < 5;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isLowStock ? Colors.red.shade100 : Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${sellingPrice.toStringAsFixed(2)} / ${item['unit'] ?? ''}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹${itemTotal.toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).primaryColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('CURRENT STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item['quantity'] ?? 0} ${item['unit'] ?? ''}',
                                            style: TextStyle(
                                              color: isLowStock ? Colors.red : Colors.grey.shade700,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade100),
                                        ),
                                        child: Row(
                                          children: [
                                            _qtyBtn(Icons.remove, () => billing.updateQuantity(index, -1), isDangerous: true),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text(
                                                billQty is double ? billQty.toStringAsFixed(isUnit ? 0 : 2) : '$billQty',
                                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                            _qtyBtn(Icons.add, () => billing.updateQuantity(index, 1)),
                                          ],
                                        ),
                                      ),
                                    ],
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

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isDangerous = false}) {
    return Material(
      color: isDangerous ? Colors.orange.shade50 : Theme.of(context).primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: isDangerous ? Colors.orange.shade700 : Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _bottomSummary(BillingProvider billing) {
    final discountController = TextEditingController(text: billing.discount.toString());
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [

          _summaryActionTile('Discount', 
            SizedBox(
              width: 80,
              child: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(prefixText: '₹', border: InputBorder.none, isDense: true),
                onSubmitted: (v) => billing.setDiscount(double.tryParse(v) ?? 0.0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _summaryActionTile('Payment', 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _paymentChip('Cash', billing.paymentMode == 'Cash', () => billing.setPaymentMode('Cash')),
                const SizedBox(width: 8),
                _paymentChip('Credit', billing.paymentMode == 'Credit', () => billing.setPaymentMode('Credit')),
              ],
            )
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(
                '₹${billing.grandTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
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
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                billing.editingBillId != null ? 'UPDATE BILL' : 'COMPLETE CHECKOUT', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _summaryActionTile(String label, Widget action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: action,
        ),
      ],
    );
  }

  Widget _paymentChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
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
