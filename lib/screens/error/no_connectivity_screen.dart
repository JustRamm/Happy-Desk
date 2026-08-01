import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../theme/app_theme.dart';

class NoConnectivityScreen extends StatefulWidget {
  final VoidCallback? onReconnected;

  const NoConnectivityScreen({super.key, this.onReconnected});

  @override
  State<NoConnectivityScreen> createState() => _NoConnectivityScreenState();
}

class _NoConnectivityScreenState extends State<NoConnectivityScreen> {
  bool _isChecking = false;

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 800)); // smooth user feedback

    final connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() => _isChecking = false);

    final isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      if (widget.onReconnected != null) {
        widget.onReconnected!();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still offline. Please check your Wi-Fi or cellular network.'),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Offline Signal Icon
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4B7BF5).withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFF4B7BF5),
                  size: 64,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Connection Lost',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'You are currently offline. Any mood logs, clock-in actions, or queued chat messages will be stored locally in cache and automatically synced to the company database once you reconnect.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5.toPrecision(1),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Offline Cache Sync Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF7F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00AE88).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_queue_rounded, color: Color(0xFF00AE88), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Offline actions cache is ACTIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005844),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Try Reconnecting Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0DDD9),
                    elevation: 3,
                    shadowColor: AppTheme.primaryRust.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.wifi_rounded, size: 20),
                  label: Text(
                    _isChecking ? 'Checking Connection...' : 'Check Connection Again',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension DoubleExtension on double {
  double toPrecision(int fractionDigits) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}
