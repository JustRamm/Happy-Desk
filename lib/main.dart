import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_wrapper_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HappyDeskApp());
}

class HappyDeskApp extends StatelessWidget {
  const HappyDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Desk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingWrapperScreen(),
    );
  }
}
