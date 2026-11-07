import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskModel? initialTask;
  final DateTime? defaultDate;

  const TaskFormScreen({super.key, this.initialTask, this.defaultDate});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _remarksController;

  late DateTime _taskDate;
  TimeOfDay? _taskTime;
  String _priority = AppConstants.priorityMedium;
  String _status = AppConstants.taskStatusPending;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _remarksController = TextEditingController(text: t?.remarks ?? '');

    _taskDate = t?.taskDate ?? widget.defaultDate ?? DateTime.now();
    _taskTime = DateFormatter.parseTimeOfDay(t?.taskTime);
    if (t != null) {
      _priority = t.priority;
      _status = t.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _taskDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _taskDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _taskTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _taskTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final timeStr =
        _taskTime != null ? DateFormatter.formatTimeOfDay(_taskTime) : null;

    if (widget.initialTask == null) {
      final task = TaskModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        taskDate: _taskDate,
        taskTime: timeStr,
        priority: _priority,
        status: _status,
        remarks: _remarksController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(tasksProvider.notifier).addTask(task);
    } else {
      final updated = widget.initialTask!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        taskDate: _taskDate,
        taskTime: timeStr,
        priority: _priority,
        status: _status,
        remarks: _remarksController.text.trim(),
      );
      await ref.read(tasksProvider.notifier).updateTask(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialTask == null
              ? 'Task created successfully!'
              : 'Task updated successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Call supplier, Deliver client demo, Deposit cheque...',
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter task title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Task Description / Details',
                  hintText: 'Add agenda, requirements, or address details...',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Schedule Date & Time',
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
                        'Date: ${DateFormatter.formatDate(_taskDate)}',
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
                        _taskTime != null
                            ? DateFormatter.formatTimeOfDay(_taskTime)
                            : 'Select Time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Priority Level',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.taskPriorities.map((pri) {
                  final isSelected = _priority == pri;
                  Color priColor;
                  switch (pri) {
                    case AppConstants.priorityHigh:
                      priColor = AppColors.danger;
                      break;
                    case AppConstants.priorityMedium:
                      priColor = AppColors.warning;
                      break;
                    default:
                      priColor = AppColors.teal;
                  }
                  return ChoiceChip(
                    label: Text(
                      pri,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: priColor,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? priColor : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _priority = pri);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              if (isEditing) ...[
                const Text(
                  'Task Status',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Pending',
                        style: TextStyle(
                          color: _status == AppConstants.taskStatusPending
                              ? Colors.white
                              : const Color(0xFF92400E),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: _status == AppConstants.taskStatusPending,
                      selectedColor: const Color(0xFFD97706),
                      backgroundColor: const Color(0xFFFEF3C7),
                      side: BorderSide(
                        color: _status == AppConstants.taskStatusPending
                            ? const Color(0xFFD97706)
                            : const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                              () => _status = AppConstants.taskStatusPending);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        'Completed',
                        style: TextStyle(
                          color: _status == AppConstants.taskStatusCompleted
                              ? Colors.white
                              : const Color(0xFF065F46),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: _status == AppConstants.taskStatusCompleted,
                      selectedColor: AppColors.successDark,
                      backgroundColor: const Color(0xFFD1FAE5),
                      side: BorderSide(
                        color: _status == AppConstants.taskStatusCompleted
                            ? AppColors.successDark
                            : const Color(0xFF10B981),
                        width: 1.5,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                              () => _status = AppConstants.taskStatusCompleted);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Post-Completion Notes',
                  hintText: 'Any outcome, notes, or next action items...',
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
                    : Text(isEditing ? 'Save Changes' : 'Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
