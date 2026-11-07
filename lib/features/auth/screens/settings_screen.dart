import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/notification_service.dart';
import '../../../core/widgets/custom_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifyLeads = true;
  bool _notifyTasks = true;
  bool _notifyExpenses = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyLeads =
          prefs.getBool(NotificationService.keyNotifyLeads) ?? true;
      _notifyTasks =
          prefs.getBool(NotificationService.keyNotifyTasks) ?? true;
      _notifyExpenses =
          prefs.getBool(NotificationService.keyNotifyExpenses) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updatePref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Theme Appearance Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette_outlined,
                              color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dark Mode'),
                        subtitle: const Text(
                            'Comfortable high-contrast dark theme'),
                        value: isDark,
                        onChanged: (val) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notifications Preferences Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              color: AppColors.indigo),
                          SizedBox(width: 10),
                          Text(
                            'Business Reminders & Alerts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lead Follow-up Alerts'),
                        subtitle: const Text(
                            'Notify when scheduled lead follow-up is due'),
                        value: _notifyLeads,
                        onChanged: (val) {
                          setState(() => _notifyLeads = val);
                          _updatePref(NotificationService.keyNotifyLeads, val);
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily Planner Tasks Reminders'),
                        subtitle: const Text(
                            'Notify for upcoming and overdue tasks'),
                        value: _notifyTasks,
                        onChanged: (val) {
                          setState(() => _notifyTasks = val);
                          _updatePref(NotificationService.keyNotifyTasks, val);
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Future Expense Due Alerts'),
                        subtitle: const Text(
                            'Notify for due and overdue scheduled expenses'),
                        value: _notifyExpenses,
                        onChanged: (val) {
                          setState(() => _notifyExpenses = val);
                          _updatePref(NotificationService.keyNotifyExpenses, val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Business Configuration Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.currency_rupee_rounded,
                              color: AppColors.teal),
                          SizedBox(width: 10),
                          Text(
                            'Currency & Localization',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Base Currency'),
                          Text('INR (₹ - Indian Rupee)',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Date Format'),
                          Text('DD-MM-YYYY',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time Format'),
                          Text('12-Hour (hh:mm AM/PM)',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // About card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'About BizPilot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'BizPilot – Business Manager is built for modern entrepreneurs, freelancers, salespeople, and service providers to operate leads, track customer payments, manage expenses, and plan their daily agenda.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Version'),
                          Text('1.0.0 (Production Build)',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
