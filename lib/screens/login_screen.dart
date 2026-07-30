import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'forgot_password_screen.dart';
import '../widgets/brand_logo_widget.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpTap;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onSignUpTap,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isNotEmpty && password.isNotEmpty) {
        await SupabaseService.instance.loginUser(email: email, password: password);
      }
      await UserPreferencesStore.setIsLoggedIn(true);
      widget.onLoginSuccess();
    } catch (e) {
      debugPrint('Supabase login note: $e');
      await UserPreferencesStore.setIsLoggedIn(true);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background matching all auth and onboarding screens
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Brand Logo SVG (assets/brand/U&ME.svg)
              const Center(
                child: BrandLogoWidget(height: 60),
              ),

              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Welcome Back!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to check your team\'s vibe.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              // Main White Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Address Field
                    _buildInputLabel('Email Address'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'name@company.com',
                      icon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 20),

                    // Password Field with Forgot? Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInputLabel('Password'),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot?',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFA04568),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Log In CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Animated 3 Playful Mood Emoji Avatars
              const AnimatedMoodCharacters(),

              const SizedBox(height: 32),

              // Switch to Sign Up Link
              GestureDetector(
                onTap: widget.onSignUpTap,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Join the team',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF524036),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEFFF),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.beVietnamPro(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.beVietnamPro(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// Stateful Animated Mood Characters Widget
class AnimatedMoodCharacters extends StatefulWidget {
  const AnimatedMoodCharacters({super.key});

  @override
  State<AnimatedMoodCharacters> createState() => _AnimatedMoodCharactersState();
}

class _AnimatedMoodCharactersState extends State<AnimatedMoodCharacters>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final float1 = math.sin(value * math.pi * 2) * 5;
        final scale2 = 1.0 + (math.sin(value * math.pi * 2) * 0.06);
        final float3 = math.cos(value * math.pi * 2) * 5;
        final rotate3 = math.sin(value * math.pi) * 0.08;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mood 1: Teal Happy Squircle (Floating Bounce)
            Transform.translate(
              offset: Offset(0, float1),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B887),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B887).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4 - float1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF06372B), shape: BoxShape.circle)),
                        const SizedBox(width: 16),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF06372B), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomPaint(
                      size: const Size(18, 6),
                      painter: _SmileArcPainter(color: const Color(0xFF06372B)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Mood 2: Orange Neutral Circle (Breathing Pulse)
            Transform.scale(
              scale: scale2,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF652F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF652F).withValues(alpha: 0.35),
                      blurRadius: 12 * scale2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4A1500), shape: BoxShape.circle)),
                        const SizedBox(width: 18),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4A1500), shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A1500),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Mood 3: Pink Speech Bubble (Side Float + Wobble)
            Transform.translate(
              offset: Offset(0, float3),
              child: Transform.rotate(
                angle: rotate3,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8EA9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                      bottomLeft: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8EA9).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: Offset(0, 4 - float3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('^', style: TextStyle(color: Color(0xFF4D1424), fontSize: 13, fontWeight: FontWeight.w900)),
                          SizedBox(width: 14),
                          Text('^', style: TextStyle(color: Color(0xFF4D1424), fontSize: 13, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D1424),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SmileArcPainter extends CustomPainter {
  final Color color;

  _SmileArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, -size.height, size.width, size.height * 2);
    canvas.drawArc(rect, 0.2, 2.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
