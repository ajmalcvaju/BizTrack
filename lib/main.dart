import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/utils/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Local notifications init notice: $e');
  }

  // Initialize Firebase (failsafe so app boots immediately in all conditions)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init fallback: $e');
  }

  runApp(
    const ProviderScope(
      child: BizPilotApp(),
    ),
  );
}
