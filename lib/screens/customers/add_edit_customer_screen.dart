import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../utils/snackbar_utils.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.customer!['name'] ?? '';
      _phoneController.text = widget.customer!['phone'] ?? '';
      _addressController.text = widget.customer!['address'] ?? '';
    }
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final Map<String, dynamic> customerData = {
          'name': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        };

        final provider = context.read<CustomerProvider>();
        if (_isEditing) {
          await provider.updateCustomer(widget.customer!['_id'], customerData);
        } else {
          await provider.addCustomer(customerData);
        }

        if (mounted) {
          SnackbarUtils.showSuccess(context, _isEditing ? 'Customer Updated!' : 'Customer Added!');
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'Add Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Place / Address', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'UPDATE CUSTOMER' : 'SAVE CUSTOMER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
