import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import 'customer_credit_detail_screen.dart';

class CreditCustomersScreen extends StatefulWidget {
  const CreditCustomersScreen({super.key});

  @override
  State<CreditCustomersScreen> createState() => _CreditCustomersScreenState();
}

class _CreditCustomersScreenState extends State<CreditCustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCreditBalances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: () => context.read<CustomerProvider>().fetchCreditBalances()
          )
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.creditCustomers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_score, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No credit customers found.'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.creditCustomers.length,
            itemBuilder: (context, index) {
              final customer = provider.creditCustomers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    child: Text(customer['name'][0].toUpperCase()),
                  ),
                  title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('📞 ${customer['phone']} \n📍 ${customer['address'] ?? ''}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer['balance'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Total Owed: ₹${customer['totalCredit'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerCreditDetailScreen(customer: customer),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
