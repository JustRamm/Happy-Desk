import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'ai_wellness_bot_screen.dart';
import 'chat_notifications_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<AiWellnessBotScreenState> _mochiScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    AiWellnessBotScreen(key: _mochiScreenKey),
    const ChatNotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          if (_currentIndex == 1 && index != 1) {
            _mochiScreenKey.currentState?.summarizeSessionIfNeeded();
          }
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
