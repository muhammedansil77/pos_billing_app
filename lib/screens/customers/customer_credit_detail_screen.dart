import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/api_service.dart';

class CustomerCreditDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerCreditDetailScreen({super.key, required this.customer});

  @override
  State<CustomerCreditDetailScreen> createState() => _CustomerCreditDetailScreenState();
}

class _CustomerCreditDetailScreenState extends State<CustomerCreditDetailScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _bills = [];
  List<dynamic> _payments = [];
  bool _isLoading = true;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final bills = await _apiService.getBills(
        customer: widget.customer['_id'],
        paymentMode: 'Credit',
      );
      final payments = await _apiService.getPayments(widget.customer['_id']);
      
      double paidSum = 0;
      for (var p in payments) {
        paidSum += (p['amount'] as num).toDouble();
      }

      setState(() {
        _bills = bills;
        _payments = payments;
        _totalPaid = paidSum;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _balance => ((widget.customer['totalCredit'] ?? 0.0) as num).toDouble() - _totalPaid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer['name']}\'s Credit'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDetails)
        ],
      ),
      body: Column(
        children: [
          // Header Summary
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.red[50],
            width: double.infinity,
            child: Column(
              children: [
                const Text('Remaining Balance', style: TextStyle(color: Colors.red, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '₹${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text('Owed: ₹${(widget.customer['totalCredit'] ?? 0.0).toStringAsFixed(2)}  |  Paid: ₹${_totalPaid.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showPaymentDialog,
                  icon: const Icon(Icons.payment),
                  label: const Text('RECEIVE PAYMENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.black,
                    indicatorColor: Colors.red,
                    tabs: [
                      Tab(text: 'BILL HISTORY'),
                      Tab(text: 'PAYMENT LOGS'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBillList(),
                        _buildPaymentList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_bills.isEmpty) return const Center(child: Text('No credit bills.'));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _bills.length,
      itemBuilder: (context, index) {
        final bill = _bills[index];
        final date = DateTime.parse(bill['createdAt']);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('Invoice: ${bill['invoiceNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date)),
            trailing: Text('₹${bill['grandTotal'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _viewBillDetails(bill),
          ),
        );
      },
    );
  }

  Widget _buildPaymentList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_payments.isEmpty) return const Center(child: Text('No payments recorded.'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final pay = _payments[index];
        final date = DateTime.parse(pay['createdAt']);
        return ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
          title: Text('Payment Received: ₹${pay['amount'].toStringAsFixed(2)}'),
          subtitle: Text('${DateFormat('dd MMM yyyy, hh:mm a').format(date)} (${pay['paymentMethod']})'),
        );
      },
    );
  }

  void _showPaymentDialog() {
    final amountController = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '₹ '),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: method,
                isExpanded: true,
                onChanged: (v) => setDialogState(() => method = v!),
                items: ['Cash', 'UPI', 'Bank Transfer', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                
                try {
                  await _apiService.createPayment({
                    'customer': widget.customer['_id'],
                    'amount': amount,
                    'paymentMethod': method,
                  });
                  Navigator.pop(context);
                  _fetchDetails();
                  context.read<CustomerProvider>().fetchCreditBalances(); // Update list too
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('SAVE PAYMENT'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBillDetails(Map<String, dynamic> bill) {
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
              const Text('Credit Bill Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    _detailRow('Invoice #', bill['invoiceNumber']),
                    _detailRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(bill['createdAt']))),
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
                    _detailRow('Grand Total', '₹${(bill['grandTotal'] ?? 0.0).toStringAsFixed(2)}', isBold: true, color: Colors.red),
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
