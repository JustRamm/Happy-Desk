import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

class LocationErrorScreen extends StatefulWidget {
  final VoidCallback? onResolved;

  const LocationErrorScreen({super.key, this.onResolved});

  @override
  State<LocationErrorScreen> createState() => _LocationErrorScreenState();
}

class _LocationErrorScreenState extends State<LocationErrorScreen> {
  bool _isChecking = false;

  Future<void> _checkLocationSetup() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Check GPS service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => _isChecking = false);
      _showSnack('GPS location services are still turned off on your device.');
      return;
    }

    // Check permission status
    var permission = await Permission.location.status;
    if (!mounted) return;
    if (permission.isGranted || permission.isLimited) {
      setState(() => _isChecking = false);
      if (widget.onResolved != null) {
        widget.onResolved!();
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }

    // Attempt requesting permission again
    final requestedStatus = await Permission.location.request();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (requestedStatus.isGranted || requestedStatus.isLimited) {
      if (widget.onResolved != null) {
        widget.onResolved!();
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      _showSnack('Location permission was denied. Please allow location access in your System Settings.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
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

              // Map Marker alert icon
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryRust.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppTheme.primaryRust,
                  size: 64,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Location Access Required',
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
                'U & ME uses GPS geo-fencing to match your current branch address coordinates during check-ins and check-outs. Without location access, we cannot verify your workplace status.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.2,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Guides / Steps
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: Column(
                  children: [
                    _buildStepRow(1, 'Ensure GPS location/services are toggled ON in your notification panel.'),
                    const Divider(height: 20),
                    _buildStepRow(2, 'Tap "Open Device Settings" below and grant "While using the app" permission.'),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.primaryRust.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  label: Text(
                    'Open Device Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm resolution
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isChecking ? null : _checkLocationSetup,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDCDAF0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.titleDark,
                          ),
                        )
                      : const Icon(Icons.done_all_rounded, size: 18, color: AppTheme.titleDark),
                  label: Text(
                    'I Have Enabled GPS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.titleDark,
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

  Widget _buildStepRow(int step, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0EB),
            shape: BoxShape.circle,
          ),
          child: Text(
            step.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryRust,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              color: AppTheme.titleDark,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
