import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'task_form_screen.dart';

class DayPlannerScreen extends ConsumerStatefulWidget {
  const DayPlannerScreen({super.key});

  @override
  ConsumerState<DayPlannerScreen> createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends ConsumerState<DayPlannerScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  Future<void> _deleteTask(BuildContext context, TaskModel task) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Task',
      message: 'Delete "${task.title}"?',
      confirmText: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    }
  }

  void _showAddRemarksDialog(BuildContext context, TaskModel task) {
    final remarksController = TextEditingController(text: task.remarks);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add / Edit Task Remarks'),
        content: TextField(
          controller: remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter notes or execution outcome...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated =
                  task.copyWith(remarks: remarksController.text.trim());
              await ref.read(tasksProvider.notifier).updateTask(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Remarks'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overdueList = state.overdueTasks;
    final dateTasks = state.filteredTasksForDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Planner'),
        actions: [
          IconButton(
            icon: Icon(state.isCalendarView
                ? Icons.view_list_rounded
                : Icons.calendar_month_rounded),
            onPressed: () =>
                ref.read(tasksProvider.notifier).toggleViewMode(),
            tooltip: state.isCalendarView ? 'List View' : 'Calendar View',
          ),
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TaskFormScreen(defaultDate: state.selectedDate),
                ),
              );
            },
            tooltip: 'Add Task',
          ),
        ],
      ),
      body: Column(
        children: [
          // Overdue Banner Alert if any
          if (overdueList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF2E1919) : const Color(0xFFFEF2F2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${overdueList.length} Overdue Task(s) pending from earlier dates!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Daily Progress Indicator Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.isToday(state.selectedDate)
                                ? "Today's Completion Progress"
                                : "Selected Day's Progress",
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Text(
                        '${state.todayCompletedCount}/${state.todayTasks.length} Completed (${(state.todayProgress * 100).toInt()}%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: state.todayProgress >= 1.0 &&
                                  state.todayTasks.isNotEmpty
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.todayProgress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        state.todayProgress >= 1.0 && state.todayTasks.isNotEmpty
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Calendar View Header (if toggled)
          if (state.isCalendarView) ...[
            CustomCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: state.selectedDate,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) =>
                    DateFormatter.isSameDay(state.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  ref
                      .read(tasksProvider.notifier)
                      .setSelectedDate(selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  titleTextStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else ...[
            // Date picker bar for list view
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      ref.read(tasksProvider.notifier).setSelectedDate(
                            state.selectedDate
                                .subtract(const Duration(days: 1)),
                          );
                    },
                    tooltip: 'Previous Day',
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        ref
                            .read(tasksProvider.notifier)
                            .setSelectedDate(picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.isToday(state.selectedDate)
                              ? 'Today (${DateFormatter.formatDate(state.selectedDate)})'
                              : DateFormatter.formatDate(state.selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      ref.read(tasksProvider.notifier).setSelectedDate(
                            state.selectedDate.add(const Duration(days: 1)),
                          );
                    },
                    tooltip: 'Next Day',
                  ),
                ],
              ),
            ),
          ],

          // Filter Chips: Priority & Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    'All',
                    style: TextStyle(
                      color: state.priorityFilter == null &&
                              state.statusFilter == null
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1E293B)),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected: state.priorityFilter == null &&
                      state.statusFilter == null,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: state.priorityFilter == null &&
                            state.statusFilter == null
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                  onSelected: (_) {
                    ref.read(tasksProvider.notifier).setPriorityFilter(null);
                    ref.read(tasksProvider.notifier).setStatusFilter(null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    'Pending',
                    style: TextStyle(
                      color: state.statusFilter == AppConstants.taskStatusPending
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFF92400E)),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected:
                      state.statusFilter == AppConstants.taskStatusPending,
                  selectedColor: const Color(0xFFD97706),
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark
                      ? const Color(0xFF451A03)
                      : const Color(0xFFFEF3C7),
                  side: BorderSide(
                    color: state.statusFilter == AppConstants.taskStatusPending
                        ? const Color(0xFFD97706)
                        : (isDark ? AppColors.warning : const Color(0xFFF59E0B)),
                    width: 1.5,
                  ),
                  onSelected: (_) => ref
                      .read(tasksProvider.notifier)
                      .setStatusFilter(
                          state.statusFilter == AppConstants.taskStatusPending
                              ? null
                              : AppConstants.taskStatusPending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    'Completed',
                    style: TextStyle(
                      color: state.statusFilter ==
                              AppConstants.taskStatusCompleted
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFF065F46)),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected:
                      state.statusFilter == AppConstants.taskStatusCompleted,
                  selectedColor: AppColors.successDark,
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFD1FAE5),
                  side: BorderSide(
                    color: state.statusFilter ==
                            AppConstants.taskStatusCompleted
                        ? AppColors.successDark
                        : (isDark ? AppColors.success : const Color(0xFF10B981)),
                    width: 1.5,
                  ),
                  onSelected: (_) => ref
                      .read(tasksProvider.notifier)
                      .setStatusFilter(
                          state.statusFilter == AppConstants.taskStatusCompleted
                              ? null
                              : AppConstants.taskStatusCompleted),
                ),
                const SizedBox(width: 8),
                ...AppConstants.taskPriorities.map((pri) {
                  final isSel = state.priorityFilter == pri;
                  Color priColor;
                  Color priBg;
                  Color priBorder;
                  Color priTextColor;

                  switch (pri) {
                    case AppConstants.priorityHigh:
                      priColor = AppColors.dangerDark;
                      priBg = isDark
                          ? const Color(0xFF450A0A)
                          : const Color(0xFFFEE2E2);
                      priBorder =
                          isDark ? AppColors.danger : const Color(0xFFEF4444);
                      priTextColor = isDark
                          ? const Color(0xFFFECDD3)
                          : const Color(0xFF9F1239);
                      break;
                    case AppConstants.priorityMedium:
                      priColor = const Color(0xFFD97706);
                      priBg = isDark
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFEF3C7);
                      priBorder =
                          isDark ? AppColors.warning : const Color(0xFFF59E0B);
                      priTextColor = isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E);
                      break;
                    case AppConstants.priorityLow:
                    default:
                      priColor = AppColors.teal;
                      priBg = isDark
                          ? const Color(0xFF042F2E)
                          : const Color(0xFFCCFBF1);
                      priBorder =
                          isDark ? AppColors.tealLight : const Color(0xFF14B8A6);
                      priTextColor = isDark
                          ? const Color(0xFF99F6E4)
                          : const Color(0xFF115E59);
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        '$pri Priority',
                        style: TextStyle(
                          color: isSel ? Colors.white : priTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: priColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: priBg,
                      side: BorderSide(
                        color: isSel ? priColor : priBorder,
                        width: 1.5,
                      ),
                      onSelected: (_) => ref
                          .read(tasksProvider.notifier)
                          .setPriorityFilter(isSel ? null : pri),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Main Task List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Separate Overdue Tasks Section (Requirement 8)
                if (overdueList.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Overdue Tasks (Requires Immediate Action)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...overdueList.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TaskCard(
                          task: task,
                          onToggle: () => ref
                              .read(tasksProvider.notifier)
                              .toggleTaskStatus(task),
                          onEdit: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskFormScreen(initialTask: task),
                              ),
                            );
                          },
                          onDelete: () => _deleteTask(context, task),
                          onAddRemarks: () =>
                              _showAddRemarksDialog(context, task),
                        ),
                      )),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                ],

                // 2. Tasks for Selected Day
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.isToday(state.selectedDate)
                          ? "Today's Tasks"
                          : "Tasks for ${DateFormatter.formatDate(state.selectedDate)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${dateTasks.length} Tasks',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.lightTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (dateTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateView(
                      icon: Icons.task_alt_rounded,
                      title: 'No tasks scheduled',
                      description:
                          'Plan your meetings, client follow-ups, and operational tasks.',
                      buttonText: 'Add Task for this Day',
                      onButtonPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(
                                defaultDate: state.selectedDate),
                          ),
                        );
                      },
                    ),
                  )
                else
                  ...dateTasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TaskCard(
                          task: task,
                          onToggle: () => ref
                              .read(tasksProvider.notifier)
                              .toggleTaskStatus(task),
                          onEdit: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskFormScreen(initialTask: task),
                              ),
                            );
                          },
                          onDelete: () => _deleteTask(context, task),
                          onAddRemarks: () =>
                              _showAddRemarksDialog(context, task),
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  TaskFormScreen(defaultDate: state.selectedDate),
            ),
          );
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddRemarks;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddRemarks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOverdue = task.isOverdue;

    // Overdue task logic: If a task is not marked as completed by the end of its scheduled date,
    // display it in red from the next day.
    return CustomCard(
      padding: const EdgeInsets.all(14),
      borderColor: isOverdue ? AppColors.danger : null,
      color: isOverdue
          ? (isDark ? const Color(0xFF2C1919) : const Color(0xFFFEF2F2))
          : (task.isCompleted
              ? (isDark ? const Color(0xFF14271F) : const Color(0xFFF0FDF4))
              : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox / Completion Toggle
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    task.isCompleted
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: task.isCompleted
                        ? AppColors.success
                        : (isOverdue ? AppColors.danger : AppColors.primary),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? AppColors.lightTextMuted
                            : (isOverdue ? AppColors.dangerDark : null),
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isOverdue)
                StatBadge.overdue()
              else
                StatBadge.forPriority(task.priority),
            ],
          ),
          const SizedBox(height: 10),

          // Schedule & action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isOverdue
                        ? AppColors.danger
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormatter.formatDate(task.taskDate)}${task.taskTime != null ? " at ${task.taskTime}" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isOverdue ? FontWeight.bold : FontWeight.normal,
                      color: isOverdue
                          ? AppColors.danger
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment_outlined, size: 18),
                    onPressed: onAddRemarks,
                    tooltip: 'Add / Edit Remarks',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit Task',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    onPressed: onDelete,
                    tooltip: 'Delete Task',
                  ),
                ],
              ),
            ],
          ),
          if (task.remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Note: ${task.remarks}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
