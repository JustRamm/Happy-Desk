import 'package:flutter/material.dart';
import '../screens/chat/call_history_screen.dart';

class CallHistoryButtonWidget extends StatelessWidget {
  const CallHistoryButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CallHistoryScreen(),
          ),
        );
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.phone_outlined,
          color: Color(0xFFAB3500),
          size: 22,
        ),
      ),
      tooltip: 'Call History',
    );
  }
}
