import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_wrapper_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Intercept known Flutter Web engine browser window resize assertion errors
  // (e.g. ViewInsets cannot be negative when resizing devtools or browser viewport)
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('ViewInsets') || msg.contains('isNonNegative')) {
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final msg = error.toString();
    if (msg.contains('ViewInsets') || msg.contains('isNonNegative')) {
      return true; // Suppress web engine window resize calculation assertion
    }
    return false;
  };

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
