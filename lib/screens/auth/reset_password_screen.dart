import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Color(0xFF00AE88),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLength = _passwordController.text.trim().length >= 6;
    final passwordsMatch = _passwordController.text.trim().isNotEmpty &&
        _passwordController.text.trim() == _confirmController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: Text(
          'Security & Password',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: AppTheme.titleDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.titleDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppTheme.primaryRust,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Set New Password',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a strong password to protect your corporate U & ME profile.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // New Password Field
              Text(
                'NEW PASSWORD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              Text(
                'CONFIRM NEW PASSWORD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checklist Criteria
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: Column(
                  children: [
                    _buildCriteriaRow(hasLength, 'At least 6 characters long'),
                    const Divider(height: 20),
                    _buildCriteriaRow(passwordsMatch, 'Passwords match exactly'),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRust,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE0DDD9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
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

  Widget _buildCriteriaRow(bool met, String text) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: met ? const Color(0xFF00AE88) : AppTheme.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: met ? FontWeight.w700 : FontWeight.w500,
              color: met ? AppTheme.titleDark : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
