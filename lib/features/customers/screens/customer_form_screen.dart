import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../../leads/providers/leads_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerModel? initialCustomer;
  final String? prefilledLeadId;
  final String? initialShopName;
  final String? initialCustomerName;
  final String? initialPhone;
  final String? initialAddress;
  final String? initialRemarks;

  const CustomerFormScreen({
    super.key,
    this.initialCustomer,
    this.prefilledLeadId,
    this.initialShopName,
    this.initialCustomerName,
    this.initialPhone,
    this.initialAddress,
    this.initialRemarks,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _customerNameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _workDetailsController;
  late TextEditingController _totalAmountController;
  late TextEditingController _remarksController;

  String _workStatus = AppConstants.workStatusNotStarted;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _shopNameController =
        TextEditingController(text: c?.shopName ?? widget.initialShopName ?? '');
    _customerNameController = TextEditingController(
        text: c?.customerName ?? widget.initialCustomerName ?? '');
    _contactController =
        TextEditingController(text: c?.contactNumber ?? widget.initialPhone ?? '');
    _addressController =
        TextEditingController(text: c?.address ?? widget.initialAddress ?? '');
    _workDetailsController =
        TextEditingController(text: c?.workDetails ?? '');
    _totalAmountController = TextEditingController(
      text: c != null ? CurrencyFormatter.toRupees(c.totalWorkAmount).toStringAsFixed(0) : '',
    );
    _remarksController = TextEditingController(
        text: c?.customerRemarks ?? widget.initialRemarks ?? '');

    if (c != null) {
      _workStatus = c.workStatus;
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _customerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _workDetailsController.dispose();
    _totalAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final totalPaise =
        CurrencyFormatter.parseRupeesToPaise(_totalAmountController.text);

    if (widget.initialCustomer == null) {
      final newCustomer = CustomerModel(
        id: '',
        shopName: _shopNameController.text.trim(),
        customerName: _customerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        workDetails: _workDetailsController.text.trim(),
        workStatus: _workStatus,
        customerRemarks: _remarksController.text.trim(),
        totalWorkAmount: totalPaise,
        totalAmountReceived: 0,
        createdAt: DateTime.now(),
      );

      final custId =
          await ref.read(customersProvider.notifier).addCustomer(newCustomer);

      // If created from lead conversion, update lead status as converted
      if (widget.prefilledLeadId != null) {
        await ref
            .read(leadsProvider.notifier)
            .markLeadConverted(widget.prefilledLeadId!, custId);
      }
    } else {
      final updated = widget.initialCustomer!.copyWith(
        shopName: _shopNameController.text.trim(),
        customerName: _customerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        workDetails: _workDetailsController.text.trim(),
        workStatus: _workStatus,
        customerRemarks: _remarksController.text.trim(),
        totalWorkAmount: totalPaise,
      );
      await ref.read(customersProvider.notifier).updateCustomer(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialCustomer == null
              ? 'Customer added successfully!'
              : 'Customer record updated!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialCustomer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _shopNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Shop / Business Name *',
                  prefixIcon: Icon(Icons.store_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter shop name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customerNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Customer / Owner Name *',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter customer name'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone Number',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Shop / Delivery Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _workDetailsController,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Work / Project Details',
                  hintText: 'e.g. Website development, billing hardware, solar setup...',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Work Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.workStatuses.map((status) {
                  final isSelected = _workStatus == status;
                  return ChoiceChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _workStatus = status);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _totalAmountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Total Work Amount (₹) *',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter total work amount';
                  }
                  final val = double.tryParse(v.trim());
                  if (val == null || val < 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Customer Remarks & Notes',
                  hintText: 'Any special contract notes, terms, or customer requests...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Customer Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
