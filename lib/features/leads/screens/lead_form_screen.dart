import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/lead_model.dart';
import '../providers/leads_provider.dart';

class LeadFormScreen extends ConsumerStatefulWidget {
  final LeadModel? initialLead;

  const LeadFormScreen({super.key, this.initialLead});

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _customerNameController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _remarksController;

  String _responseStatus = AppConstants.leadStatusFollowUp;
  DateTime? _nextFollowUpDate;
  TimeOfDay? _nextFollowUpTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final lead = widget.initialLead;
    _shopNameController = TextEditingController(text: lead?.shopName ?? '');
    _customerNameController =
        TextEditingController(text: lead?.customerName ?? '');
    _contactController = TextEditingController(text: lead?.contactNumber ?? '');
    _addressController = TextEditingController(text: lead?.address ?? '');
    _remarksController =
        TextEditingController(text: lead?.customerRemarks ?? '');

    if (lead != null) {
      _responseStatus = lead.responseStatus;
      _nextFollowUpDate = lead.nextFollowUpDate;
      _nextFollowUpTime = DateFormatter.parseTimeOfDay(lead.nextFollowUpTime);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _customerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowUpDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _nextFollowUpDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _nextFollowUpTime ?? const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) {
      setState(() => _nextFollowUpTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final timeStr = _nextFollowUpTime != null
        ? DateFormatter.formatTimeOfDay(_nextFollowUpTime)
        : null;

    if (widget.initialLead == null) {
      // Create new lead
      final newLead = LeadModel(
        id: '',
        shopName: _shopNameController.text.trim(),
        customerName: _customerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        responseStatus: _responseStatus,
        nextFollowUpDate: _nextFollowUpDate,
        nextFollowUpTime: timeStr,
        customerRemarks: _remarksController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(leadsProvider.notifier).addLead(newLead);
    } else {
      // Update existing lead
      final updatedLead = widget.initialLead!.copyWith(
        shopName: _shopNameController.text.trim(),
        customerName: _customerNameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        address: _addressController.text.trim(),
        responseStatus: _responseStatus,
        nextFollowUpDate: _nextFollowUpDate,
        nextFollowUpTime: timeStr,
        clearFollowUp: _nextFollowUpDate == null,
        customerRemarks: _remarksController.text.trim(),
      );
      await ref.read(leadsProvider.notifier).updateLead(updatedLead);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialLead == null
              ? 'Lead generated successfully!'
              : 'Lead updated successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialLead != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Lead' : 'Add New Lead'),
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
                    v == null || v.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _customerNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Customer / Contact Person Name *',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Customer name is required'
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
                  labelText: 'Shop Address / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Response Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.leadStatuses.map((status) {
                  final isSelected = _responseStatus == status;
                  Color activeColor;
                  Color bgTint;
                  Color textColor;
                  switch (status) {
                    case AppConstants.leadStatusInterested:
                      activeColor = AppColors.successDark;
                      bgTint = const Color(0xFFD1FAE5);
                      textColor = const Color(0xFF065F46);
                      break;
                    case AppConstants.leadStatusFollowUp:
                      activeColor = const Color(0xFFD97706);
                      bgTint = const Color(0xFFFEF3C7);
                      textColor = const Color(0xFF92400E);
                      break;
                    case AppConstants.leadStatusDNP:
                      activeColor = AppColors.dangerDark;
                      bgTint = const Color(0xFFFEE2E2);
                      textColor = const Color(0xFF9F1239);
                      break;
                    default:
                      activeColor = AppColors.primary;
                      bgTint = const Color(0xFFF1F5F9);
                      textColor = const Color(0xFF1E293B);
                  }
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: activeColor,
                    backgroundColor: bgTint,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: activeColor,
                      width: 1.5,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _responseStatus = status);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text(
                'Scheduled Follow-up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        _nextFollowUpDate != null
                            ? DateFormatter.formatDate(_nextFollowUpDate)
                            : 'Select Date',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        _nextFollowUpTime != null
                            ? DateFormatter.formatTimeOfDay(_nextFollowUpTime)
                            : 'Select Time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_nextFollowUpDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      tooltip: 'Clear Follow-up',
                      onPressed: () {
                        setState(() {
                          _nextFollowUpDate = null;
                          _nextFollowUpTime = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Customer Remarks / Requirements',
                  hintText: 'Enter notes from conversation or product interest...',
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
                    : Text(isEditing ? 'Save Changes' : 'Generate Lead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
