import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ServerErrorScreen extends StatefulWidget {
  final VoidCallback onRetry;
  final String? errorMessage;

  const ServerErrorScreen({super.key, required this.onRetry, this.errorMessage});

  @override
  State<ServerErrorScreen> createState() => _ServerErrorScreenState();
}

class _ServerErrorScreenState extends State<ServerErrorScreen> {
  bool _isRetrying = false;

  Future<void> _triggerRetry() async {
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isRetrying = false);
    widget.onRetry();
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

              // Database Outage Icon
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryRust.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppTheme.primaryRust,
                  size: 64,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Server Power Nap',
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
                'Our company servers are currently undergoing temporary maintenance or are experiencing high traffic. Please check back in a few moments.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.2,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EEFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2DEEE)),
                  ),
                  child: Text(
                    widget.errorMessage!,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11,
                      color: const Color(0xFF3B2A66),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              // Retry Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _triggerRetry,
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
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded, size: 20),
                  label: Text(
                    _isRetrying ? 'Connecting to Cloud...' : 'Try Reconnecting',
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
