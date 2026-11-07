import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime taskDate;
  final String? taskTime; // "hh:mm a"
  final String priority; // Low, Medium, High
  final String status; // Pending, Completed
  final String remarks;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.taskDate,
    this.taskTime,
    this.priority = AppConstants.priorityMedium,
    this.status = AppConstants.taskStatusPending,
    this.remarks = '',
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  bool get isCompleted => status == AppConstants.taskStatusCompleted;

  DateTime get scheduledDateTime {
    final parsed = DateFormatter.parseTimeOfDay(taskTime);
    return DateFormatter.combineDateAndTime(
      taskDate,
      parsed ?? const TimeOfDay(hour: 23, minute: 59),
    );
  }

  /// Overdue task logic:
  /// If a task is not marked as completed by the end of its scheduled date,
  /// display it in red from the next day. Continue displaying the task as overdue until it is completed.
  bool get isOverdue {
    if (isCompleted) return false;
    return DateFormatter.isPastDate(taskDate);
  }

  bool get isDueToday {
    if (isCompleted) return false;
    return DateFormatter.isToday(taskDate);
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      taskDate: (data['taskDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taskTime: data['taskTime'],
      priority: data['priority'] ?? AppConstants.priorityMedium,
      status: data['status'] ?? AppConstants.taskStatusPending,
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'taskDate': Timestamp.fromDate(taskDate),
      'taskTime': taskTime,
      'priority': priority,
      'status': status,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? taskDate,
    String? taskTime,
    String? priority,
    String? status,
    String? remarks,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskDate: taskDate ?? this.taskDate,
      taskTime: taskTime ?? this.taskTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: DateTime.now(),
    );
  }
}
