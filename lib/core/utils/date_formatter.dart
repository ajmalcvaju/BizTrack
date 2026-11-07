import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MM-yyyy hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MM-yyyy');
  static final DateFormat _monthNameYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayDateHeaderFormat = DateFormat('EEEE, dd MMMM yyyy');

  /// Format DateTime to DD-MM-YYYY
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date.toLocal());
  }

  /// Format DateTime to 12-hour format: 02:30 PM
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeFormat.format(date.toLocal());
  }

  /// Format TimeOfDay to 12-hour format: 02:30 PM
  static String formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return _timeFormat.format(dt);
  }

  /// Format DateTime to DD-MM-YYYY hh:mm a
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return _dateTimeFormat.format(date.toLocal());
  }

  /// Format to MM-yyyy (e.g. 11-2026)
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date.toLocal());
  }

  /// Format to "November 2026"
  static String formatMonthNameYear(DateTime date) {
    return _monthNameYearFormat.format(date.toLocal());
  }

  /// Format for dashboard header: "Wednesday, 04 November 2026"
  static String formatHeaderDate(DateTime date) {
    return _dayDateHeaderFormat.format(date.toLocal());
  }

  /// Parse DD-MM-YYYY to DateTime
  static DateTime? parseDate(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      return _dateFormat.parseStrict(input.trim());
    } catch (_) {
      try {
        return DateTime.parse(input);
      } catch (_) {
        return null;
      }
    }
  }

  /// Parse 12-hour time string like "02:30 PM" to TimeOfDay
  static TimeOfDay? parseTimeOfDay(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    try {
      final dt = _timeFormat.parseStrict(input.trim());
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return null;
    }
  }

  /// Combine date and TimeOfDay into a single DateTime in local timezone
  static DateTime combineDateAndTime(DateTime date, TimeOfDay? time) {
    final localDate = date.toLocal();
    final hour = time?.hour ?? 0;
    final minute = time?.minute ?? 0;
    return DateTime(localDate.year, localDate.month, localDate.day, hour, minute);
  }

  /// Check if two dates are the same calendar day in local time
  static bool isSameDay(DateTime a, DateTime b) {
    final aLocal = a.toLocal();
    final bLocal = b.toLocal();
    return aLocal.year == bLocal.year &&
        aLocal.month == bLocal.month &&
        aLocal.day == bLocal.day;
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if a date is before today (strictly previous day or earlier)
  /// Used for Task Overdue rule: "If a task is not marked as completed by the end of its scheduled date, display it in red from the next day."
  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final targetMidnight = DateTime(date.year, date.month, date.day);
    return targetMidnight.isBefore(todayMidnight);
  }

  /// Check if a DateTime has passed the current moment
  static bool isPastMoment(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }
}
