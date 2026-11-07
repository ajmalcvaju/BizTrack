import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Setting keys
  static const String keyNotifyLeads = 'notify_leads';
  static const String keyNotifyTasks = 'notify_tasks';
  static const String keyNotifyExpenses = 'notify_expenses';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
        },
      );
      _isInitialized = true;
    } catch (e) {
      // In web or restricted environments, local notifications might fail gracefully
    }
  }

  Future<bool> _isCategoryEnabled(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? categoryKey,
    String? payload,
  }) async {
    if (categoryKey != null) {
      final enabled = await _isCategoryEnabled(categoryKey);
      if (!enabled) return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'bizpilot_main_channel',
      'BizPilot Business Alerts',
      channelDescription: 'Reminders for leads, tasks, and payments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (_) {}
  }

  // Quick helper methods
  Future<void> notifyLeadFollowup({
    required String leadId,
    required String shopName,
    required String customerName,
    required bool isDue,
  }) async {
    await showNotification(
      id: leadId.hashCode,
      title: isDue ? '⚠️ Lead Follow-up Due' : 'Upcoming Follow-up',
      body: '$customerName ($shopName) is scheduled for follow-up.',
      categoryKey: keyNotifyLeads,
      payload: 'lead:$leadId',
    );
  }

  Future<void> notifyTask({
    required String taskId,
    required String taskTitle,
    required bool isOverdue,
  }) async {
    await showNotification(
      id: taskId.hashCode,
      title: isOverdue ? '🚨 Overdue Task Alert' : '📋 Task Reminder',
      body: isOverdue
          ? '"$taskTitle" was scheduled for an earlier date and is still pending!'
          : '"$taskTitle" is scheduled for today.',
      categoryKey: keyNotifyTasks,
      payload: 'task:$taskId',
    );
  }

  Future<void> notifyFutureExpense({
    required String expenseId,
    required String title,
    required String amountFormatted,
    required bool isOverdue,
  }) async {
    await showNotification(
      id: expenseId.hashCode,
      title: isOverdue ? '🚨 Overdue Expense Alert' : '📅 Upcoming Expense Due',
      body: isOverdue
          ? '"$title" ($amountFormatted) is overdue! Please mark it as paid.'
          : '"$title" ($amountFormatted) is due today.',
      categoryKey: keyNotifyExpenses,
      payload: 'expense:$expenseId',
    );
  }
}
