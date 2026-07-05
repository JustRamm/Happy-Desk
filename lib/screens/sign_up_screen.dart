import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onSignUpSuccess;

  const SignUpScreen({
    super.key,
    required this.onLoginTap,
    required this.onSignUpSuccess,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0; // 0 = Step 1 (Personal Credentials), 1 = Step 2 (Role & Workspace Setup)
  String _selectedRole = 'team'; // 'team' or 'founder'

  // Step 1 Controllers (Credentials)
  final _nameController = TextEditingController(text: 'Alex Miller');
  final _emailController = TextEditingController(text: 'alex@company.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  // Step 2 Controllers (Role & Workspace Details)
  final _inviteCodeController = TextEditingController(text: 'HAPPY-8821');
  final _jobRoleController = TextEditingController(text: 'Product Designer');
  final _workspaceNameController = TextEditingController(text: 'Acme Studio');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    _jobRoleController.dispose();
    _workspaceNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background matching all auth screens
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Brand Logo & Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_currentStep == 1)
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                        color: AppTheme.titleDark, size: 18),
                                    onPressed: _previousStep,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (_currentStep == 1) const SizedBox(width: 8),
                                Image.asset(
                                  'assets/brand/logo_removedbg.png',
                                  height: 38,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),

                            // Step Indicator Pill
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRust.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _currentStep == 0 ? 'Step 1 of 2' : 'Step 2 of 2',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryRust,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Animated Step Transition Container
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeInOutCubic,
                          switchOutCurve: Curves.easeInOutCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _currentStep == 0
                              ? _buildStepOneCard(key: const ValueKey('step_1'))
                              : _buildStepTwoCard(key: const ValueKey('step_2')),
                        ),

                        const SizedBox(height: 16),

                        // Social Proof Cards Row
                        Row(
                          children: [
                            // Card 1: 1,200+ Teams Connected
                            Expanded(
                              child: Container(
                                height: 115,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B887), // Emerald Green
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00B887).withValues(alpha: 0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFF06372B),
                                        size: 16,
                                      ),
                                    ),
                                    Text(
                                      '1,200+ Teams\nConnected',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF06372B),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Card 2: Join a thriving community
                            Expanded(
                              child: Transform.rotate(
                                angle: 0.02,
                                child: Container(
                                  height: 115,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8EA9), // Soft Pink
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8EA9).withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Overlapping Avatars
                                      Row(
                                        children: [
                                          _buildSmallAvatar('assets/avatars/user_avatar.png'),
                                          Transform.translate(
                                            offset: const Offset(-8, 0),
                                            child:
                                                _buildSmallAvatar('assets/avatars/user_avatar.png'),
                                          ),
                                          Transform.translate(
                                            offset: const Offset(-16, 0),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF652F),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Text(
                                                '+1k',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Join a thriving\ncommunity',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF4D1424),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Spacer to push copyright text to very bottom of screen
                        const Spacer(),

                        const SizedBox(height: 16),

                        // Footer Copyright at Very Bottom
                        Text(
                          '© 2024 Happy Desk. All tasks turned into play.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1 CARD: Name, Work Email, Password & Continue Button
  // ---------------------------------------------------------------------------
  Widget _buildStepOneCard({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Create Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.titleDark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Enter your basic details to get started.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Full Name Field
          _buildInputLabel('Full Name'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameController,
            hintText: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 14),

          // Work Email Field
          _buildInputLabel('Work Email'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hintText: 'alex@company.com',
            icon: Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 14),

          // Password Field
          _buildInputLabel('Password'),
          const SizedBox(height: 6),
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

          const SizedBox(height: 20),

          // Continue Button to Step 2
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRust,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppTheme.primaryRust.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Or continue with Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Or continue with',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 14),

          // Sign Up with Google Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _nextStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoogleIcon(),
                  const SizedBox(width: 10),
                  Text(
                    'Sign up with Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.titleDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Already a member? Log in link
          Center(
            child: GestureDetector(
              onTap: widget.onLoginTap,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Already a member? '),
                    TextSpan(
                      text: 'Log In',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryRust,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2 CARD: Select Role (Founder / Team Member), Invite Code & Job Role
  // ---------------------------------------------------------------------------
  Widget _buildStepTwoCard({required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Select Your Role',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.titleDark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Tell us how you will be using Happy Desk.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Role Selection Cards (Team Member vs Founder/Leader)
          Row(
            children: [
              // Role Option 1: Team Member
              Expanded(
                child: _buildRoleCard(
                  id: 'team',
                  title: 'Team Member',
                  subtitle: 'Joining an existing team',
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 12),

              // Role Option 2: Founder / Leader
              Expanded(
                child: _buildRoleCard(
                  id: 'founder',
                  title: 'Founder / Leader',
                  subtitle: 'Managing company & team',
                  icon: Icons.workspace_premium_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Dynamic Inputs based on selected role
          if (_selectedRole == 'team') ...[
            // Team Member Fields
            _buildInputLabel('Team Invite Code'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _inviteCodeController,
              hintText: 'e.g. HAPPY-8821',
              icon: Icons.vpn_key_outlined,
            ),

            const SizedBox(height: 14),

            _buildInputLabel('Your Job Role'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _jobRoleController,
              hintText: 'e.g. Product Designer, Engineer',
              icon: Icons.badge_outlined,
            ),
          ] else ...[
            // Founder / Leader Fields
            _buildInputLabel('Workspace / Company Name'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _workspaceNameController,
              hintText: 'e.g. Acme Studio Inc.',
              icon: Icons.business_rounded,
            ),

            const SizedBox(height: 14),

            _buildInputLabel('Your Job Title'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _jobRoleController,
              hintText: 'e.g. CEO, Head of People',
              icon: Icons.work_outline_rounded,
            ),
          ],

          const SizedBox(height: 20),

          // Join the Team Button (Final Submit - No Emoji!)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onSignUpSuccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRust,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppTheme.primaryRust.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Join the Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Already a member? Log in link
          Center(
            child: GestureDetector(
              onTap: widget.onLoginTap,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Already a member? '),
                    TextSpan(
                      text: 'Log In',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryRust,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: Role Card Option (Team Member vs Founder)
  Widget _buildRoleCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryRust.withValues(alpha: 0.08)
              : const Color(0xFFF4F4FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRust : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? AppTheme.primaryRust : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryRust : AppTheme.titleDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.titleDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.grey.shade500,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 19),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    size: 19,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(String assetPath) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double stroke = w * 0.22;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: (w - stroke) / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, math.pi * 1.05, math.pi * 0.45, false, paint);

    // Yellow (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.60, math.pi * 0.45, false, paint);

    // Green (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.1, math.pi * 0.50, false, paint);

    // Blue (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, math.pi * 1.5, math.pi * 0.6, false, paint);

    // Blue center horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - stroke / 2, w / 2, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
