import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/billing_provider.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () => context.read<SalesProvider>().fetchBills()
          )
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, child) {
          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _filterChip(context, 'today', 'Today'),
                    _filterChip(context, 'yesterday', 'Yesterday'),
                    _filterChip(context, 'custom', 'Custom Date', isCustom: true),
                    const SizedBox(width: 8),
                    _paymentModeDropdown(context),
                  ],
                ),
              ),
              
              // Total Sales & Profit Summary
              _summaryCard(salesProvider),

              Expanded(
                child: salesProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : salesProvider.bills.isEmpty
                        ? const Center(child: Text('No sales records found for this period.'))
                        : ListView.builder(
                            itemCount: salesProvider.bills.length,
                            itemBuilder: (context, index) {
                              final bill = salesProvider.bills[index];
                              final date = DateTime.parse(bill['date'] ?? bill['createdAt']);
                              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                              final customerName = bill['customer'] != null ? bill['customer']['name'] : 'Walk-in';
                              final billProfit = salesProvider.calculateBillProfit(bill);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple[50],
                                    child: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                                  ),
                                  title: Text(
                                    'Invoice: ${bill['invoiceNumber']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$customerName • $formattedDate'),
                                      Text(
                                        'Profit: ₹${billProfit.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '₹${bill['grandTotal'].toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  onTap: () => _showBillDetails(context, bill, salesProvider),
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

  Widget _summaryCard(SalesProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.deepPurple.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Sales', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '₹${provider.totalSalesAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Profit', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '₹${provider.totalProfit.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${provider.bills.length} Invoices Found', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String filter, String label, {bool isCustom = false}) {
    final provider = context.watch<SalesProvider>();
    final isSelected = provider.currentFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (bool selected) async {
          if (isCustom) {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: provider.customDateRange,
            );
            if (picked != null) {
              provider.setCustomRange(picked);
            }
          } else {
            provider.setFilter(filter);
          }
        },
        selectedColor: Colors.deepPurple[100],
        checkmarkColor: Colors.deepPurple,
      ),
    );
  }

  Widget _paymentModeDropdown(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    return Container(
      height: 32, // Match FilterChip height approximately
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.paymentModeFilter,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setPaymentModeFilter(newValue);
            }
          },
          items: <String>['All', 'Cash', 'Credit']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBillDetails(BuildContext context, Map<String, dynamic> bill, SalesProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bill Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      context.read<BillingProvider>().loadBillForEditing(bill);
                      Navigator.pop(context); // close bottom sheet
                      Navigator.pushNamed(context, '/pos'); // go to POS
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Bill'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      backgroundColor: Colors.deepPurple.withAlpha(20),
                    ),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _detailRow('Invoice #', bill['invoiceNumber']),
                    _detailRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(bill['date'] ?? bill['createdAt']))),
                    const Divider(height: 30),
                    const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...((bill['items'] ?? []) as List).map((item) => ListTile(
                          title: Text(item['name'] ?? ''),
                          subtitle: Text('Qty: ${item['quantity']}'),
                          trailing: Text('₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}'),
                        )),
                    const Divider(height: 30),
                    _detailRow('Subtotal', '₹${(bill['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
                    _detailRow('GST', '₹${(bill['totalGst'] ?? 0.0).toStringAsFixed(2)}'),
                    _detailRow('Discount', '₹${(bill['discount'] ?? 0.0).toStringAsFixed(2)}', color: Colors.red),
                    _detailRow('Grand Total', '₹${(bill['grandTotal'] ?? 0.0).toStringAsFixed(2)}', isBold: true),
                    const Divider(height: 20),
                    _detailRow('Total Profit', '₹${provider.calculateBillProfit(bill).toStringAsFixed(2)}', isBold: true, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: color)),
        ],
      ),
    );
  }
}
