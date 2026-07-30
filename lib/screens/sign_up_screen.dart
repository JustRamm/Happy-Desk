import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_widget.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

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
  // 0 = Role Selection, 1 = Credentials, 2 = Profile & Avatar, 3 = Workplace Details
  int _currentStep = 0;
  String _selectedRole = ''; // 'employee' or 'founder'
  bool _isLeadershipRole = false; // For employees: team lead / manager checkbox
  String _generatedLeaderCode = '';
  String _selectedAvatar = '';
  String _selectedDepartment = 'Design';
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _departments = [
    'Design',
    'Engineering',
    'Operations',
    'Marketing',
    'People / HR',
  ];

  // Step 1 Controllers (Credentials)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2 Controllers (Profile Details)
  final _jobRoleController = TextEditingController();
  final _bioController = TextEditingController();

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Profile Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF0EB),
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.primaryRust),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEBF7F5),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF00AE88)),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _selectedAvatar = picked.path;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open image picker. Please try again.'),
          ),
        );
      }
    }
  }

  // Step 3 Controllers (Workplace & Company Details)
  final _inviteCodeController = TextEditingController();
  final _workspaceNameController = TextEditingController();
  final _hqLocationController = TextEditingController();
  final _industryController = TextEditingController();
  String _selectedCompanySize = '11-50 employees';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _jobRoleController.dispose();
    _bioController.dispose();
    _inviteCodeController.dispose();
    _workspaceNameController.dispose();
    _hqLocationController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  String _generateCode({String prefix = 'COMP'}) {
    final rand = math.Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$prefix-$code';
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedRole.isEmpty) return;
      if (_selectedRole == 'employee' && _isLeadershipRole && _generatedLeaderCode.isEmpty) {
        _generatedLeaderCode = _generateCode();
      }
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _performSupabaseRegistration();
    }
  }

  Future<void> _performSupabaseRegistration() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final jobTitle = _selectedRole == 'founder'
        ? 'Founder & CEO'
        : (_jobRoleController.text.trim().isNotEmpty
            ? _jobRoleController.text.trim()
            : 'Employee');
    final companyName = _workspaceNameController.text.trim();
    final hqLocation = _hqLocationController.text.trim();
    final industry = _industryController.text.trim();
    final bioText = _bioController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address and password.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedAvatar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a profile photo using gallery or camera.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedRole == 'founder' && companyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Company / Workspace Name.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedRole == 'employee' && _inviteCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the Company Join Code provided by your Founder.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Store local profile
    await UserPreferencesStore.setUserProfile(
      name: name.isNotEmpty ? name : (_selectedRole == 'founder' ? 'Founder' : 'Employee'),
      role: jobTitle,
      team: _selectedRole == 'founder' ? 'Executive Leadership' : _selectedDepartment,
      bio: bioText,
      company: companyName.isNotEmpty ? companyName : 'Happy Desk HQ',
    );

    if (_selectedRole == 'founder') {
      final compCode = _generatedLeaderCode.isNotEmpty ? _generatedLeaderCode : _generateCode(prefix: 'COMP');
      await UserPreferencesStore.setRoleType('founder');
      await UserPreferencesStore.setUserRole('Founder & CEO');
      await UserPreferencesStore.setCompanyCode(compCode);
      await UserPreferencesStore.setCompanyDetails(
        companyName: companyName,
        hqLocation: hqLocation,
        industry: industry,
        companySize: _selectedCompanySize,
      );
    } else {
      await UserPreferencesStore.setRoleType('employee');
      await UserPreferencesStore.setUserRole(jobTitle);
      await UserPreferencesStore.setIsLeader(_isLeadershipRole);
      await UserPreferencesStore.setCompanyCode(_inviteCodeController.text.trim());
      if (_isLeadershipRole) {
        final teamCode = _generatedLeaderCode.isNotEmpty ? _generatedLeaderCode : _generateCode(prefix: 'TEAM');
        await UserPreferencesStore.setTeamCode(teamCode);
      }
    }

    if (_selectedAvatar.isNotEmpty) {
      await UserPreferencesStore.setUserAvatarUrl(_selectedAvatar);
    }

    try {
      String? uploadedAvatarUrl;

      if (_selectedRole == 'founder') {
        final compCode = UserPreferencesStore.getCompanyCode();
        final authRes = await SupabaseService.instance.signUpFounder(
          email: email,
          password: password,
          name: name.isNotEmpty ? name : 'Founder',
          companyName: companyName,
          hqLocation: hqLocation,
          industry: industry,
          companySize: _selectedCompanySize,
          companyCode: compCode,
          jobTitle: 'Founder & CEO',
          department: 'Executive Leadership',
          bio: bioText,
        );
        if (authRes.user != null && _selectedAvatar.isNotEmpty && File(_selectedAvatar).existsSync()) {
          uploadedAvatarUrl = await SupabaseService.instance.uploadAvatarImage(File(_selectedAvatar));
        }
      } else {
        final code = _inviteCodeController.text.trim();
        final authRes = await SupabaseService.instance.signUpEmployee(
          email: email,
          password: password,
          name: name.isNotEmpty ? name : 'Employee',
          companyCode: code.isNotEmpty ? code : 'COMP-DEMO',
          isLeader: _isLeadershipRole,
          jobTitle: jobTitle,
          department: _selectedDepartment,
          bio: bioText,
        );
        if (authRes.user != null && _selectedAvatar.isNotEmpty && File(_selectedAvatar).existsSync()) {
          uploadedAvatarUrl = await SupabaseService.instance.uploadAvatarImage(File(_selectedAvatar));
        }
      }

      if (uploadedAvatarUrl != null) {
        await UserPreferencesStore.setUserAvatarUrl(uploadedAvatarUrl);
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          await SupabaseService.instance.client.from('profiles').update({
            'avatar_url': uploadedAvatarUrl,
          }).eq('id', user.id);
        }
      }
      await UserPreferencesStore.setIsLoggedIn(true);
    } catch (e) {
      debugPrint('Supabase registration note: $e');
      await UserPreferencesStore.setIsLoggedIn(true);
    } finally {
      widget.onSignUpSuccess();
    }
  }

  int get _totalSteps => 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
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

                        // Top Header Bar: Logo & Step Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const BrandLogoWidget(height: 38),

                            // Step Indicator Pill
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRust.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Step ${_currentStep + 1} of $_totalSteps',
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

                        // Animated Step Content Page Switcher
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
                          child: _buildCurrentStepCard(),
                        ),

                        const SizedBox(height: 16),

                        // Social Proof Cards Row
                        Row(
                          children: [
                            // Card 1: Teams Connected
                            Expanded(
                              child: Container(
                                height: 105,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B887),
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

                                      ],
                        ),

                        const Spacer(),

                        const SizedBox(height: 16),

                        // Footer Copyright
                        Text(
                          '2026 U & ME. All tasks turned into play.',
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

  Widget _buildCurrentStepCard() {
    switch (_currentStep) {
      case 0:
        return _buildStepZeroRoleSelection(key: const ValueKey('step_0'));
      case 1:
        return _buildStepOneCredentials(key: const ValueKey('step_1'));
      case 2:
        return _buildStepTwoProfile(key: const ValueKey('step_2'));
      case 3:
        return _buildStepThreeWorkplace(key: const ValueKey('step_3'));
      default:
        return _buildStepZeroRoleSelection(key: const ValueKey('step_0'));
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 0: Role Selection (Founder / Employee)
  // ---------------------------------------------------------------------------
  Widget _buildStepZeroRoleSelection({required Key key}) {
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
              'How will you be using U & ME?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Role Selection Cards
          Row(
            children: [
              Expanded(
                child: _buildRoleSelectionCard(
                  id: 'founder',
                  title: 'Founder / Admin',
                  subtitle: 'Create & manage\nyour company',
                  icon: Icons.workspace_premium_rounded,
                  accentColor: const Color(0xFFFF652F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRoleSelectionCard(
                  id: 'employee',
                  title: 'Employee',
                  subtitle: 'Join an existing\nworkplace',
                  icon: Icons.badge_rounded,
                  accentColor: const Color(0xFF4B7BF5),
                ),
              ),
            ],
          ),

          // Employee Leadership Checkbox (only visible when employee is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: _selectedRole == 'employee'
                ? Column(
                    children: [
                      const SizedBox(height: 18),

                      // Leadership checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLeadershipRole = !_isLeadershipRole;
                            if (!_isLeadershipRole) {
                              _generatedLeaderCode = '';
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isLeadershipRole
                                ? const Color(0xFFFFF3EE)
                                : const Color(0xFFF4F4FD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isLeadershipRole
                                  ? AppTheme.primaryRust.withValues(alpha: 0.4)
                                  : const Color(0xFFE4E7FE),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _isLeadershipRole
                                      ? AppTheme.primaryRust
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _isLeadershipRole
                                        ? AppTheme.primaryRust
                                        : const Color(0xFFBFC3D9),
                                    width: 2,
                                  ),
                                ),
                                child: _isLeadershipRole
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'I have a leadership role',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.titleDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Team Lead, Manager, or Department Head',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Show generated code for leaders, or invite code input for regular employees
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: _isLeadershipRole
                            ? _buildLeaderCodeSection()
                            : _buildEmployeeInviteSection(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Founder workspace name (only visible when founder is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: _selectedRole == 'founder'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      _buildInputLabel('Workspace / Company Name'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _workspaceNameController,
                        hintText: 'e.g. Acme Studio Inc.',
                        icon: Icons.business_rounded,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 22),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedRole.isNotEmpty ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRust,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0DDD9),
                disabledForegroundColor: const Color(0xFF9E9A95),
                elevation: _selectedRole.isNotEmpty ? 3 : 0,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
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

  /// Section shown when employee has leadership role checked - displays generated code
  Widget _buildLeaderCodeSection() {
    if (_generatedLeaderCode.isEmpty) {
      // Generate button
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _generatedLeaderCode = _generateCode();
              });
            },
            icon: const Icon(Icons.vpn_key_rounded, size: 18),
            label: Text(
              'Generate Your Leader Code',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryRust,
              side: BorderSide(color: AppTheme.primaryRust.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
    }

    // Show generated code with copy button
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FBF7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00AE88).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00AE88),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.key_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  'Your Leader Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF005844),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00AE88).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _generatedLeaderCode,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF005844),
                      letterSpacing: 3,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _generatedLeaderCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Code copied to clipboard',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF00AE88),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AE88).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Color(0xFF00AE88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with your team members so they can join.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF006C53),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section shown when employee does NOT have leadership role - invite code input
  Widget _buildEmployeeInviteSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Team Invite Code'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _inviteCodeController,
            hintText: 'e.g. LEAD-ABC123',
            icon: Icons.vpn_key_outlined,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the code shared by your team lead or admin.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Account Credentials & Password Match Check
  // ---------------------------------------------------------------------------
  Widget _buildStepOneCredentials({required Key key}) {
    final passwordsMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
    final isFounder = _selectedRole == 'founder';

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
              isFounder ? 'Set Up Founder Account' : 'Create Your Account',
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
              isFounder
                  ? 'Enter credentials for your executive admin account'
                  : 'Enter your login credentials',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Full Name Field
          _buildInputLabel(isFounder ? 'Founder / Admin Name' : 'Full Name'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameController,
            hintText: isFounder ? 'e.g. Sarah Connor' : 'Full Name',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 14),

          // Work Email Field
          _buildInputLabel(isFounder ? 'Executive Email' : 'Work Email'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hintText: isFounder ? 'founder@company.com' : 'alex@company.com',
            icon: Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 14),

          // Password Field
          _buildInputLabel('Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            onChanged: (val) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Confirm Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputLabel('Confirm Password'),
              if (_confirmPasswordController.text.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      passwordsMatch
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: passwordsMatch
                          ? const Color(0xFF00AE88)
                          : const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: passwordsMatch
                            ? const Color(0xFF00AE88)
                            : const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Re-enter password',
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            onChanged: (val) => setState(() {}),
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
                    isFounder ? 'Continue to Executive Profile' : 'Continue to Profile Setup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Profile Customization & Avatar Upload
  // ---------------------------------------------------------------------------
  Widget _buildStepTwoProfile({required Key key}) {
    final isFounder = _selectedRole == 'founder';
    final deptList = isFounder
        ? ['Executive', 'Leadership & Ops', 'Product', 'Engineering', 'Marketing']
        : ['Design', 'Engineering', 'Operations', 'Marketing', 'People / HR'];

    if (isFounder && !_departments.contains(_selectedDepartment) && !deptList.contains(_selectedDepartment)) {
      _selectedDepartment = 'Executive';
    }

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
              isFounder ? 'Executive Profile & Vision' : 'Customize Your Profile',
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
              isFounder
                  ? 'Set executive title & company bio'
                  : 'Upload photo & enter job role',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Avatar Upload / Picker Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryRust, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryRust.withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(43),
                          child: _selectedAvatar.startsWith('assets/')
                              ? Image.asset(_selectedAvatar, fit: BoxFit.cover)
                              : Image.file(File(_selectedAvatar), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryRust,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the avatar to choose a photo from your gallery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          if (!isFounder) ...[
            // Job Title / Role (Employees only)
            _buildInputLabel('Job Title / Position'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _jobRoleController,
              hintText: 'e.g. Product Designer, Software Engineer',
              icon: Icons.work_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],

          // Department Selection Chips
          _buildInputLabel(isFounder ? 'Executive Department' : 'Department'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: deptList.map((dept) {
              final isSelected = _selectedDepartment == dept;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(dept),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.titleDark,
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryRust,
                backgroundColor: const Color(0xFFF4F4FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryRust
                        : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDepartment = dept;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Short Bio / Motto
          _buildInputLabel(isFounder ? 'Company Vision / Founder Bio' : 'Bio / Personal Motto'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _bioController,
            hintText: isFounder
                ? 'e.g. Building our company culture & driving vision!'
                : 'e.g. Building delightful products & team spirit!',
            icon: Icons.chat_bubble_outline_rounded,
          ),

          const SizedBox(height: 20),

          // Continue Button to Step 3
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
                    isFounder ? 'Next: Review Workspace Setup' : 'Next: Finalize Setup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Final Review & Account Creation
  // ---------------------------------------------------------------------------
  Widget _buildStepThreeWorkplace({required Key key}) {
    final isFounder = _selectedRole == 'founder';
    final roleLabel = isFounder
        ? 'Founder & CEO (Workspace Owner)'
        : _isLeadershipRole
            ? 'Employee (Team Lead)'
            : 'Employee (Team Member)';

    final companyNameDisplay = isFounder
        ? (_workspaceNameController.text.trim().isNotEmpty
            ? _workspaceNameController.text.trim()
            : 'Acme Corp')
        : 'Joined via Team Code';

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
              isFounder ? 'Launch Company Workspace' : 'Finalize Setup',
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
              isFounder
                  ? 'Review details & activate company workspace'
                  : 'Review your details & complete signup',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          if (isFounder) ...[
            const SizedBox(height: 14),
            _buildInputLabel('Main Branch / HQ Location'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _hqLocationController,
              hintText: 'e.g. New York, USA or City/Branch',
              icon: Icons.location_city_rounded,
            ),
            const SizedBox(height: 12),
            _buildInputLabel('Company Industry / Domain'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _industryController,
              hintText: 'e.g. Software & Tech, Healthcare, Finance',
              icon: Icons.domain_rounded,
            ),
            const SizedBox(height: 12),
            _buildInputLabel('Company Size'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['1-10 employees', '11-50 employees', '51-200 employees', '200+ employees'].map((size) {
                final isSel = _selectedCompanySize == size;
                return ChoiceChip(
                  showCheckmark: false,
                  label: Text(size),
                  selected: isSel,
                  selectedColor: AppTheme.primaryRust,
                  backgroundColor: const Color(0xFFF4F4FD),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? Colors.white : AppTheme.titleDark,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCompanySize = size;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Review Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7FE)),
            ),
            child: Column(
              children: [
                _buildReviewRow(
                  isFounder ? Icons.workspace_premium_rounded : Icons.person_rounded,
                  'Role',
                  roleLabel,
                ),
                const Divider(height: 20),
                _buildReviewRow(
                  Icons.email_rounded,
                  'Email',
                  _emailController.text.isNotEmpty
                      ? _emailController.text
                      : (isFounder ? 'founder@happy-desk.app' : 'employee@happy-desk.app'),
                ),
                if (!isFounder) ...[
                  const Divider(height: 20),
                  _buildReviewRow(
                    Icons.work_rounded,
                    'Job Title',
                    _jobRoleController.text.isNotEmpty ? _jobRoleController.text : 'Employee',
                  ),
                ],
                const Divider(height: 20),
                _buildReviewRow(
                  Icons.apartment_rounded,
                  'Department',
                  isFounder ? 'Executive Leadership' : _selectedDepartment,
                ),
                if (isFounder) ...[
                  const Divider(height: 20),
                  _buildReviewRow(
                    Icons.business_rounded,
                    'Company Workspace',
                    companyNameDisplay,
                  ),
                  const Divider(height: 20),
                  _buildReviewRow(
                    Icons.location_on_rounded,
                    'HQ Location',
                    _hqLocationController.text.isNotEmpty ? _hqLocationController.text : 'New York, USA',
                  ),
                  if (_generatedLeaderCode.isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildReviewRow(
                      Icons.key_rounded,
                      'Master Join Code',
                      _generatedLeaderCode,
                    ),
                  ],
                  const Divider(height: 20),
                  _buildReviewRow(
                    Icons.admin_panel_settings_rounded,
                    'Admin Privileges',
                    'Full Executive Dashboard & Team Analytics',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Profile Ready Banner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isFounder ? const Color(0xFFFFF3EE) : const Color(0xFFEBF7F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFounder
                    ? AppTheme.primaryRust.withValues(alpha: 0.3)
                    : const Color(0xFF00AE88).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFounder ? AppTheme.primaryRust : const Color(0xFF00AE88),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFounder ? Icons.rocket_launch_rounded : Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFounder ? 'Founder Workspace 100% Ready!' : 'Profile 100% Complete!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isFounder ? AppTheme.primaryRust : const Color(0xFF005844),
                        ),
                      ),
                      Text(
                        isFounder
                            ? 'Activating your workspace will generate company join codes for your team.'
                            : 'All required details, avatar & workplace preferences saved.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11.5,
                          color: isFounder ? AppTheme.primaryRust : const Color(0xFF006C53),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Create Account Button (Final Submit)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _performSupabaseRegistration,
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
                isFounder ? 'Create Company & Launch Workspace' : 'Complete Setup & Join Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryRust),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.titleDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedRole == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = id;
          if (id == 'founder') {
            _isLeadershipRole = true;
            _selectedDepartment = 'Executive';
            if (_generatedLeaderCode.isEmpty) {
              _generatedLeaderCode = _generateCode();
            }
          } else {
            _isLeadershipRole = false;
            _selectedDepartment = 'Design';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.08)
              : const Color(0xFFF4F4FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFFE4E7FE),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : const Color(0xFFE8E7F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected ? accentColor : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : AppTheme.titleDark,
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
                height: 1.3,
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
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4FD),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
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
}
