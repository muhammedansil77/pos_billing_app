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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<SalesProvider>().fetchBills(),
          )
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, child) {
          return Column(
            children: [
              // Filter System
              Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _filterChip(context, 'today', 'Today'),
                      _filterChip(context, 'yesterday', 'Yesterday'),
                      _filterChip(context, 'custom', 'Custom Range', isCustom: true),
                      const SizedBox(width: 4),
                      _paymentModeDropdown(context),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Total Sales & Profit Summary
              _summaryCard(salesProvider),

              const SizedBox(height: 8),

              Expanded(
                child: salesProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : salesProvider.bills.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 64, color: colorScheme.primary.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                const Text('No sales records found.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: salesProvider.bills.length,
                            itemBuilder: (context, index) {
                              final bill = salesProvider.bills[index];
                              final date = DateTime.parse(bill['date'] ?? bill['createdAt']);
                              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                              final customerName = bill['customer'] != null ? bill['customer']['name'] : 'Walk-in';
                              final billProfit = salesProvider.calculateBillProfit(bill);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.receipt_rounded, color: colorScheme.primary, size: 24),
                                  ),
                                  title: Text(
                                    'INV-${bill['invoiceNumber']}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$customerName • $formattedDate',
                                          style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Profit: ₹${billProfit.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Text(
                                    '₹${bill['grandTotal'].toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL SALES', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.bills.length} Invoices',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Text(
            '₹${provider.totalSalesAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Profit', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '₹${provider.totalProfit.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFFBBF7D0), fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String filter, String label, {bool isCustom = false}) {
    final provider = context.watch<SalesProvider>();
    final isSelected = provider.currentFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
        ),
        onSelected: (bool selected) async {
          if (isCustom) {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: provider.customDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: colorScheme,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              provider.setCustomRange(picked);
            }
          } else {
            provider.setFilter(filter);
          }
        },
        selectedColor: colorScheme.primary,
        checkmarkColor: Colors.white,
        backgroundColor: colorScheme.surface,
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _paymentModeDropdown(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.paymentModeFilter,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: colorScheme.primary),
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w600),
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setPaymentModeFilter(newValue);
            }
          },
          items: <String>['All', 'Cash', 'Credit'].map<DropdownMenuItem<String>>((String value) {
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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bill Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statusTag(bill['paymentMode'] ?? 'Cash', colorScheme),
                  const SizedBox(width: 8),
                  _statusTag('INV-${bill['invoiceNumber']}', colorScheme, isOutlined: true),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    _detailRow('Customer', bill['customer'] != null ? bill['customer']['name'] : 'Walk-in'),
                    _detailRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(bill['date'] ?? bill['createdAt']))),
                    const SizedBox(height: 24),
                    Text('ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    ...((bill['items'] ?? []) as List).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Qty: ${item['quantity']}', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              Text('₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                    const Divider(height: 48),
                    _detailRow('Subtotal', '₹${(bill['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
                    _detailRow('GST', '₹${(bill['totalGst'] ?? 0.0).toStringAsFixed(2)}'),
                    _detailRow('Discount', '-₹${(bill['discount'] ?? 0.0).toStringAsFixed(2)}', color: const Color(0xFFEF4444)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(
                            '₹${(bill['grandTotal'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _detailRow('Total Profit', '₹${provider.calculateBillProfit(bill).toStringAsFixed(2)}', isBold: true, color: const Color(0xFF10B981)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<BillingProvider>().loadBillForEditing(bill);
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/pos');
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('EDIT THIS INVOICE', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusTag(String label, ColorScheme colorScheme, {bool isOutlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : colorScheme.primary.withOpacity(0.1),
        border: isOutlined ? Border.all(color: colorScheme.primary.withOpacity(0.2)) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontSize: isBold ? 16 : 14,
              color: color == Colors.black ? (isBold ? Colors.black : Colors.black87) : color,
            ),
          ),
        ],
      ),
    );
  }
}
