import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();

  runApp(const ProviderScope(child: BearTahanApp()));
}

class BearTahanApp extends StatelessWidget {
  const BearTahanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BearTahan',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
