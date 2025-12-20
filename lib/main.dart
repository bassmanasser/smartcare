import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartcare/utils/constants.dart';

import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ init local notifications + timezone
  await NotificationService.instance.init();

  runApp(const SmartCareApp());
}

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SmartCare',
            theme: ThemeData(
              scaffoldBackgroundColor: LIGHT_BG,
              colorScheme: ColorScheme.fromSeed(seedColor: PETROL),
              appBarTheme: const AppBarTheme(
                backgroundColor: PETROL_DARK,
                foregroundColor: Colors.white,
              ),
            ),
            locale: appState.locale,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
