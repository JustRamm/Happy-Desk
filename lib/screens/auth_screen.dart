import 'package:flutter/material.dart';
import 'sign_up_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsLogin;

  const AuthScreen({
    super.key,
    this.initialIsLogin = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _onAuthSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isLogin
          ? LoginScreen(
              key: const ValueKey('login'),
              onSignUpTap: _toggleAuthMode,
              onLoginSuccess: _onAuthSuccess,
            )
          : SignUpScreen(
              key: const ValueKey('signup'),
              onLoginTap: _toggleAuthMode,
              onSignUpSuccess: _onAuthSuccess,
            ),
    );
  }
}
