import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_model.dart';

class TasksState {
  final List<TaskModel> allTasks;
  final bool isLoading;
  final DateTime selectedDate;
  final String? priorityFilter;
  final String? statusFilter;
  final bool isCalendarView;

  const TasksState({
    this.allTasks = const [],
    this.isLoading = false,
    required this.selectedDate,
    this.priorityFilter,
    this.statusFilter,
    this.isCalendarView = false,
  });

  // Overdue tasks: Not completed AND scheduled date is strictly before today
  List<TaskModel> get overdueTasks =>
      allTasks.where((t) => t.isOverdue).toList();

  // Tasks for the selected date
  List<TaskModel> get tasksForSelectedDate {
    return allTasks.where((t) {
      return DateFormatter.isSameDay(t.taskDate, selectedDate);
    }).toList();
  }

  // Tasks for today
  List<TaskModel> get todayTasks {
    return allTasks.where((t) {
      return DateFormatter.isToday(t.taskDate);
    }).toList();
  }

  int get todayCompletedCount =>
      todayTasks.where((t) => t.isCompleted).length;

  int get todayPendingCount =>
      todayTasks.where((t) => !t.isCompleted).length;

  double get todayProgress {
    if (todayTasks.isEmpty) return 0.0;
    return todayCompletedCount / todayTasks.length;
  }

  // Filtered tasks for current view
  List<TaskModel> get filteredTasksForDate {
    var list = tasksForSelectedDate;
    if (priorityFilter != null && priorityFilter!.isNotEmpty) {
      list = list.where((t) => t.priority == priorityFilter).toList();
    }
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      list = list.where((t) => t.status == statusFilter).toList();
    }
    return list;
  }

  TasksState copyWith({
    List<TaskModel>? allTasks,
    bool? isLoading,
    DateTime? selectedDate,
    String? priorityFilter,
    bool clearPriorityFilter = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? isCalendarView,
  }) {
    return TasksState(
      allTasks: allTasks ?? this.allTasks,
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      isCalendarView: isCalendarView ?? this.isCalendarView,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final FirebaseService _service = FirebaseService();
  final Ref _ref;
  StreamSubscription? _subscription;

  TasksNotifier(this._ref)
      : super(TasksState(
          selectedDate: DateTime.now(),
          isLoading: true,
        )) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _subscribeToTasks(next.isDemoUser);
      } else {
        _subscription?.cancel();
        state = TasksState(selectedDate: DateTime.now());
      }
    });

    final currentAuth = _ref.read(authProvider);
    if (currentAuth.isAuthenticated) {
      _subscribeToTasks(currentAuth.isDemoUser);
    }
  }

  void _subscribeToTasks(bool isDemo) {
    _subscription?.cancel();
    if (isDemo) {
      state = state.copyWith(
        allTasks: _sampleTasks,
        isLoading: false,
      );
      _checkTaskNotifications(_sampleTasks);
      return;
    }

    state = state.copyWith(isLoading: true);
    _subscription = _service.streamTasks().listen(
      (tasks) {
        state = state.copyWith(allTasks: tasks, isLoading: false);
        _checkTaskNotifications(tasks);
      },
      onError: (_) {
        if (state.allTasks.isEmpty) {
          state = state.copyWith(
            allTasks: _sampleTasks,
            isLoading: false,
          );
        }
      },
    );
  }

  void _checkTaskNotifications(List<TaskModel> tasks) {
    for (final task in tasks) {
      if (!task.isCompleted) {
        if (task.isOverdue) {
          NotificationService().notifyTask(
            taskId: task.id,
            taskTitle: task.title,
            isOverdue: true,
          );
        } else if (task.isDueToday) {
          NotificationService().notifyTask(
            taskId: task.id,
            taskTitle: task.title,
            isOverdue: false,
          );
        }
      }
    }
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(
      priorityFilter: priority,
      clearPriorityFilter: priority == null,
    );
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  void toggleViewMode() {
    state = state.copyWith(isCalendarView: !state.isCalendarView);
  }

  Future<void> addTask(TaskModel task) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final id = task.id.isEmpty ? const Uuid().v4() : task.id;
    final finalTask = TaskModel(
      id: id,
      title: task.title,
      description: task.description,
      taskDate: task.taskDate,
      taskTime: task.taskTime,
      priority: task.priority,
      status: task.status,
      remarks: task.remarks,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      state = state.copyWith(
        allTasks: [finalTask, ...state.allTasks],
      );
    } else {
      await _service.addTask(finalTask);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updated =
          state.allTasks.map((t) => t.id == task.id ? task : t).toList();
      state = state.copyWith(allTasks: updated);
    } else {
      await _service.updateTask(task);
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final isNowCompleted = !task.isCompleted;
      final updated = task.copyWith(
        status: isNowCompleted
            ? AppConstants.taskStatusCompleted
            : AppConstants.taskStatusPending,
        completedAt: isNowCompleted ? DateTime.now() : null,
      );
      final list =
          state.allTasks.map((t) => t.id == task.id ? updated : t).toList();
      state = state.copyWith(allTasks: list);
    } else {
      await _service.toggleTaskStatus(task);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        allTasks: state.allTasks.where((t) => t.id != taskId).toList(),
      );
    } else {
      await _service.deleteTask(taskId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static final List<TaskModel> _sampleTasks = [
    TaskModel(
      id: 'task-1',
      title: 'Call Amit Sharma for POS Billing Quotation',
      description: 'Discuss 2 scanners bundle discount and finalize quote',
      taskDate: DateTime.now(),
      taskTime: '02:30 PM',
      priority: AppConstants.priorityHigh,
      status: AppConstants.taskStatusPending,
      remarks: 'Client prefers quick delivery within 3 days',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    TaskModel(
      id: 'task-2',
      title: 'Review milestone deliverable for Priya Mehta',
      description: 'Check payment gateway checkout and shipping rates configuration',
      taskDate: DateTime.now(),
      taskTime: '04:00 PM',
      priority: AppConstants.priorityMedium,
      status: AppConstants.taskStatusCompleted,
      remarks: 'Verified working smoothly on staging server',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      completedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    TaskModel(
      id: 'task-3',
      title: 'Submit GST Invoice to Delight Sweets',
      description: 'Prepare tax invoice with reverse charge details',
      taskDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue!
      taskTime: '11:00 AM',
      priority: AppConstants.priorityHigh,
      status: AppConstants.taskStatusPending,
      remarks: 'Delayed due to PAN verification delay',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TaskModel(
      id: 'task-4',
      title: 'Bank deposit for weekly cash payments',
      description: 'Deposit ₹20,000 cash collection at HDFC Bank branch',
      taskDate: DateTime.now(),
      taskTime: '05:30 PM',
      priority: AppConstants.priorityLow,
      status: AppConstants.taskStatusPending,
      remarks: '',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});
