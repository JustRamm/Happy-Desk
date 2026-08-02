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
  bool _isLoading = false;
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

  // Step 2 Coordinates & Maps Controllers for Founders
  final _hqLatitudeController = TextEditingController();
  final _hqLongitudeController = TextEditingController();
  final _hqMapsLinkController = TextEditingController();

  // Step 2 Coordinates & Maps Controllers for Leaders (Optional)
  final _teamAddressController = TextEditingController();
  final _teamLatitudeController = TextEditingController();
  final _teamLongitudeController = TextEditingController();
  final _teamMapsLinkController = TextEditingController();

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

  Future<void> _autoDetectHqCoordinates() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fetching current GPS coordinates...',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      final pos = await SupabaseService.instance.getCurrentDeviceLocation();
      if (pos != null) {
        final addressDetails = await SupabaseService.instance.fetchDetailedAddress(pos.latitude, pos.longitude);
        final addressStr = addressDetails['location_name'] ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        if (mounted) {
          setState(() {
            _hqLatitudeController.text = pos.latitude.toString();
            _hqLongitudeController.text = pos.longitude.toString();
            _hqLocationController.text = addressStr;
            _hqMapsLinkController.text = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'HQ Location auto-detected successfully!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF00AE88),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not fetch GPS coordinates. Please check your location settings.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error auto-detecting HQ coordinates: $e');
    }
  }

  Future<void> _autoDetectTeamCoordinates() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fetching current GPS coordinates...',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      final pos = await SupabaseService.instance.getCurrentDeviceLocation();
      if (pos != null) {
        final addressDetails = await SupabaseService.instance.fetchDetailedAddress(pos.latitude, pos.longitude);
        final addressStr = addressDetails['location_name'] ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        if (mounted) {
          setState(() {
            _teamLatitudeController.text = pos.latitude.toString();
            _teamLongitudeController.text = pos.longitude.toString();
            _teamAddressController.text = addressStr;
            _teamMapsLinkController.text = 'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Team location auto-detected successfully!',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF00AE88),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not fetch GPS coordinates. Please check your location settings.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error auto-detecting team coordinates: $e');
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
    _hqLatitudeController.dispose();
    _hqLongitudeController.dispose();
    _hqMapsLinkController.dispose();
    _teamAddressController.dispose();
    _teamLatitudeController.dispose();
    _teamLongitudeController.dispose();
    _teamMapsLinkController.dispose();
    super.dispose();
  }

  /// Generates a meaningful unique code.
  /// For a company: uses the company name (up to 10 chars) + 4-digit random number.
  /// For a team lead: uses their first name (up to 10 chars) + 4-digit random number.
  /// Falls back to the generic prefix if name is empty.
  String _generateCode({String prefix = 'COMP', String name = ''}) {
    final rand = math.Random();
    final digits = (1000 + rand.nextInt(9000)).toString(); // Always 4 digits
    String cleanName = name.trim().split(' ').first; // Take first word only
    // Strip any non-alphanumeric characters
    cleanName = cleanName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanName.length > 10) cleanName = cleanName.substring(0, 10);
    final effectivePrefix = cleanName.isNotEmpty ? cleanName : prefix;
    return '$effectivePrefix-$digits';
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedRole.isEmpty) return;
      // For a team lead employee, generate a code using their first name
      if (_selectedRole == 'employee' && _isLeadershipRole && _generatedLeaderCode.isEmpty) {
        _generatedLeaderCode = _generateCode(name: _nameController.text.trim());
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
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
          content: Text('Please enter your Company Name.'),
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
      company: companyName.isNotEmpty ? companyName : 'Workspace',
    );

    if (_selectedRole == 'founder') {
      // Company code uses the actual company name as the prefix
      final compCode = _generatedLeaderCode.isNotEmpty
          ? _generatedLeaderCode
          : _generateCode(name: companyName, prefix: 'COMP');
      await UserPreferencesStore.setRoleType('founder');
      await UserPreferencesStore.setUserRole('Founder & CEO');
      await UserPreferencesStore.setIsLeader(true);
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
        // Team lead code uses the team lead's first name as the prefix
        final teamCode = _generatedLeaderCode.isNotEmpty
            ? _generatedLeaderCode
            : _generateCode(name: name, prefix: 'LEAD');
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
          hqAddress: _hqLocationController.text.trim(),
          hqLatitude: double.tryParse(_hqLatitudeController.text.trim()),
          hqLongitude: double.tryParse(_hqLongitudeController.text.trim()),
          hqGoogleMapsLink: _hqMapsLinkController.text.trim(),
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
          teamAddress: _isLeadershipRole ? _teamAddressController.text.trim() : null,
          teamLatitude: _isLeadershipRole ? double.tryParse(_teamLatitudeController.text.trim()) : null,
          teamLongitude: _isLeadershipRole ? double.tryParse(_teamLongitudeController.text.trim()) : null,
          teamGoogleMapsLink: _isLeadershipRole ? _teamMapsLinkController.text.trim() : null,
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
      if (mounted) setState(() => _isLoading = false);
      widget.onSignUpSuccess();
    }
  }

  bool _isStepZeroValid() {
    if (_selectedRole.isEmpty) return false;
    if (_selectedRole == 'employee') {
      return _inviteCodeController.text.trim().isNotEmpty;
    } else if (_selectedRole == 'founder') {
      return _workspaceNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool _isStepOneValid() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    return name.isNotEmpty &&
        email.isNotEmpty &&
        pass.isNotEmpty &&
        confirm.isNotEmpty &&
        (pass == confirm);
  }

  bool _isStepTwoValid() {
    if (_selectedAvatar.isEmpty) return false;
    if (_selectedRole == 'employee') {
      return _jobRoleController.text.trim().isNotEmpty;
    } else if (_selectedRole == 'founder') {
      return _hqLocationController.text.trim().isNotEmpty &&
          _industryController.text.trim().isNotEmpty &&
          _hqLatitudeController.text.trim().isNotEmpty &&
          _hqLongitudeController.text.trim().isNotEmpty &&
          _hqMapsLinkController.text.trim().isNotEmpty;
    }
    return true;
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
                  title: 'Founder',
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
                  subtitle: 'Join an existing\ncompany',
                  icon: Icons.badge_rounded,
                  accentColor: const Color(0xFF4B7BF5),
                ),
              ),
            ],
          ),

          // Employee Leadership Checkbox & Inputs (only visible when employee is selected)
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

                      // Show invite code input for employee (always required to join company)
                      _buildEmployeeInviteSection(),

                      // Show generated code for leaders if checked
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: _isLeadershipRole
                            ? _buildLeaderCodeSection()
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // Founder company name (only visible when founder is selected)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: _selectedRole == 'founder'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      _buildInputLabel('Company Name'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _workspaceNameController,
                        hintText: 'e.g. Acme Studio Inc.',
                        icon: Icons.business_rounded,
                        onChanged: (_) => setState(() {}),
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
              onPressed: _isStepZeroValid() ? _nextStep : null,
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
                // Use the name already entered if available, else fall back to generic
                _generatedLeaderCode = _generateCode(name: _nameController.text.trim());
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
          _buildInputLabel('Company Join Code'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _inviteCodeController,
            hintText: 'e.g. COMP-5U2KG',
            icon: Icons.vpn_key_outlined,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the Company Join Code provided by your Founder.',
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
          _buildInputLabel(isFounder ? 'Founder Name' : 'Full Name'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameController,
            hintText: isFounder ? 'e.g. Sarah Connor' : 'Full Name',
            icon: Icons.person_outline_rounded,
            onChanged: (val) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // Work Email Field
          _buildInputLabel(isFounder ? 'Executive Email' : 'Work Email'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hintText: isFounder ? 'founder@company.com' : 'alex@company.com',
            icon: Icons.alternate_email_rounded,
            onChanged: (val) => setState(() {}),
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
              onPressed: _isStepOneValid() ? _nextStep : null,
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
                          child: _selectedAvatar.isEmpty
                              ? Container(
                                  color: const Color(0xFFFFF0EB),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 44,
                                    color: AppTheme.primaryRust,
                                  ),
                                )
                              : (_selectedAvatar.startsWith('assets/')
                                  ? Image.asset(_selectedAvatar, fit: BoxFit.cover)
                                  : Image.file(File(_selectedAvatar), fit: BoxFit.cover)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
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
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 14),

            // Department Selection Chips
            _buildInputLabel('Department'),
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
            if (_isLeadershipRole) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E7E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Team Branch Location (Optional)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF524036),
                          ),
                        ),
                        GestureDetector(
                          onTap: _autoDetectTeamCoordinates,
                          child: Row(
                            children: [
                              const Icon(Icons.my_location_rounded, color: AppTheme.primaryRust, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Auto-detect',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryRust,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInputLabel('Branch Address'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _teamAddressController,
                      hintText: 'e.g. Branch B, Cochin, India',
                      icon: Icons.location_on_rounded,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Latitude'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _teamLatitudeController,
                                hintText: 'e.g. 9.9312',
                                icon: Icons.map_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('Longitude'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _teamLongitudeController,
                                hintText: 'e.g. 76.2673',
                                icon: Icons.map_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInputLabel('Google Maps Link'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _teamMapsLinkController,
                      hintText: 'https://maps.google.com/?q=...',
                      icon: Icons.link_rounded,
                      onChanged: (val) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Short Bio / Motto
          _buildInputLabel(isFounder ? 'Company Vision / Founder Bio' : 'Bio / Personal Motto'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _bioController,
            hintText: isFounder
                ? 'e.g. Building our company culture & driving vision!'
                : 'e.g. Building delightful products & team spirit!',
            icon: Icons.chat_bubble_outline_rounded,
            onChanged: (val) => setState(() {}),
          ),

          if (isFounder) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInputLabel('Main Branch (Full Address)'),
                GestureDetector(
                  onTap: _autoDetectHqCoordinates,
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: AppTheme.primaryRust, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-detect',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryRust,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _hqLocationController,
              hintText: 'e.g. 123 Main St, New York, USA',
              icon: Icons.location_on_rounded,
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Latitude'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _hqLatitudeController,
                        hintText: 'e.g. 40.7128',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Longitude'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _hqLongitudeController,
                        hintText: 'e.g. -74.0060',
                        icon: Icons.map_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputLabel('Google Maps Link'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _hqMapsLinkController,
              hintText: 'https://maps.google.com/?q=...',
              icon: Icons.link_rounded,
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildInputLabel('Company Domain'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _industryController,
              hintText: 'e.g. Software & Tech',
              icon: Icons.domain_rounded,
              onChanged: (val) => setState(() {}),
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
          ],

          const SizedBox(height: 20),

          // Continue Button to Step 3
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isStepTwoValid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRust,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE0DDD9),
                disabledForegroundColor: const Color(0xFF9E9A95),
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
                    isFounder ? 'Next: Review Company Setup' : 'Next: Finalize Setup',
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
        ? 'Founder & CEO (Company Owner)'
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
              isFounder ? 'Launch Company' : 'Finalize Setup',
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
                  ? 'Review details & activate company'
                  : 'Review your details & complete signup',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

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
                    'Company Name',
                    companyNameDisplay,
                  ),
                  const Divider(height: 20),
                  _buildReviewRow(
                    Icons.location_on_rounded,
                    'Main Branch',
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
                        isFounder ? 'Founder Account 100% Ready!' : 'Profile 100% Complete!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isFounder ? AppTheme.primaryRust : const Color(0xFF005844),
                        ),
                      ),
                      Text(
                        isFounder
                            ? 'Activating your company will generate company join codes for your team.'
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
              onPressed: _isLoading ? null : _performSupabaseRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRust,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: AppTheme.primaryRust.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isFounder ? 'Launch Company' : 'Complete Setup & Join Team',
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
              // For founders, company code uses the company name
              _generatedLeaderCode = _generateCode(name: _workspaceNameController.text.trim(), prefix: 'COMP');
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
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        onTap: () {
          SystemChannels.textInput.invokeMethod('TextInput.show');
        },
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
