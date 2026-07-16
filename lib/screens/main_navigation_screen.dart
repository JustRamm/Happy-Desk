import 'package:flutter/material.dart';
import 'home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatNotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      body: Stack(
        children: List.generate(_screens.length, (index) {
          final isSelected = index == _currentIndex;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            opacity: isSelected ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !isSelected,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                scale: isSelected ? 1.0 : 0.97,
                child: _screens[index],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
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
