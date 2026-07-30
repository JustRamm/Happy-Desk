import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/user_preferences_store.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;
  late TextEditingController _workplaceController;
  late TextEditingController _hqLocationController;
  late TextEditingController _industryController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  int _selectedAvatarIndex = 0;
  File? _customImageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarOptions = [
    'assets/brand/app_icon.png',
    'assets/brand/1.png',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _customImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open image picker. You can select a preset avatar.',
              style: GoogleFonts.beVietnamPro(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFC84B1A),
          ),
        );
      }
    }
  }

  void _showAvatarPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Profile Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.titleDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8D7168)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFAB3500)),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                subtitle: Text(
                  'Upload a custom photo from your device',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF594139)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F7F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF047857)),
                ),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                subtitle: Text(
                  'Use camera to capture a new avatar',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF594139)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.face_rounded, color: Color(0xFF95416C)),
                ),
                title: Text(
                  'Cycle Preset Brand Avatar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF171B2B),
                  ),
                ),
                subtitle: Text(
                  'Switch between built-in U & ME avatars',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF594139)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _customImageFile = null;
                    _selectedAvatarIndex = (_selectedAvatarIndex + 1) % _avatarOptions.length;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserPreferencesStore.getUserName());
    _roleController = TextEditingController(text: UserPreferencesStore.getUserRole());
    _bioController = TextEditingController(text: UserPreferencesStore.getUserBio());
    _workplaceController = TextEditingController(text: UserPreferencesStore.getCompany());
    _hqLocationController = TextEditingController(text: UserPreferencesStore.getCompanyHq());
    _industryController = TextEditingController(text: UserPreferencesStore.getCompanyIndustry());
    _emailController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final profile = await SupabaseService.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          setState(() {
            _nameController.text = profile['name'] ?? _nameController.text;
            _roleController.text = profile['job_title'] ?? _roleController.text;
            _bioController.text = profile['bio'] ?? _bioController.text;
            _emailController.text = profile['email'] ?? user.email ?? '';
            _phoneController.text = profile['phone'] ?? '';
            
            final compId = profile['company_id'] as String?;
            if (compId != null) {
              _loadCompanyData(compId);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile details: $e');
    }
  }

  Future<void> _loadCompanyData(String companyId) async {
    try {
      final comp = await SupabaseService.instance.client
          .from('companies')
          .select()
          .eq('id', companyId)
          .maybeSingle();
      if (comp != null && mounted) {
        setState(() {
          _workplaceController.text = comp['name'] ?? _workplaceController.text;
          _hqLocationController.text = comp['hq_location'] ?? _hqLocationController.text;
          _industryController.text = comp['industry'] ?? _industryController.text;
        });
      }
    } catch (e) {
      debugPrint('Error loading company details: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _workplaceController.dispose();
    _hqLocationController.dispose();
    _industryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final role = _roleController.text.trim();
      final bio = _bioController.text.trim();
      final company = _workplaceController.text.trim();
      final hq = _hqLocationController.text.trim();
      final ind = _industryController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      await UserPreferencesStore.setUserName(name);
      await UserPreferencesStore.setUserRole(role);
      await UserPreferencesStore.setUserBio(bio);
      await UserPreferencesStore.setCompany(company);
      await UserPreferencesStore.setCompanyDetails(
        companyName: company,
        hqLocation: hq,
        industry: ind,
      );

      String? uploadedUrl;
      if (_customImageFile != null) {
        uploadedUrl = await SupabaseService.instance.uploadAvatarImage(_customImageFile!);
        if (uploadedUrl != null) {
          await UserPreferencesStore.setUserAvatarUrl(uploadedUrl);
        }
      }

      // Sync with Supabase backend
      try {
        final user = SupabaseService.instance.currentUser;
        if (user != null) {
          final Map<String, dynamic> updateFields = {
            'name': name,
            'job_title': role,
            'bio': bio,
            'email': email,
            'phone': phone,
          };
          if (uploadedUrl != null) {
            updateFields['avatar_url'] = uploadedUrl;
          }
          await SupabaseService.instance.client.from('profiles').update(updateFields).eq('id', user.id);

          final profileRes = await SupabaseService.instance.client
              .from('profiles')
              .select('company_id')
              .eq('id', user.id)
              .maybeSingle();

          if (profileRes != null && profileRes['company_id'] != null) {
            final companyId = profileRes['company_id'] as String;
            await SupabaseService.instance.client.from('companies').update({
              'name': company,
              'hq_location': hq,
              'industry': ind,
            }).eq('id', companyId);
          }
        }
      } catch (e) {
        debugPrint('Error syncing edited profile to Supabase: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile & Company details updated successfully!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.titleDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.titleDark,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryRust,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Picker Section
                GestureDetector(
                  onTap: _showAvatarPickerOptions,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF0EB),
                              border: Border.all(color: AppTheme.primaryRust, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _customImageFile != null
                                  ? Image.file(
                                      _customImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      _avatarOptions[_selectedAvatarIndex],
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRust,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to Change Profile Avatar',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryRust,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('FULL NAME'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _nameController,
                        hintText: 'Enter full name',
                        icon: Icons.person_outline_rounded,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Name cannot be empty' : null,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('JOB TITLE / ROLE'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _roleController,
                        hintText: 'Enter job title',
                        icon: Icons.work_outline_rounded,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('WORKPLACE / COMPANY'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _workplaceController,
                        hintText: 'Enter workplace name',
                        icon: Icons.business_outlined,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('MAIN BRANCH / HQ LOCATION'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _hqLocationController,
                        hintText: 'e.g. New York, USA or City/Branch',
                        icon: Icons.location_city_rounded,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('INDUSTRY / SECTOR'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _industryController,
                        hintText: 'e.g. Software & Tech, Healthcare, Finance',
                        icon: Icons.domain_rounded,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('PERSONAL BIO'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _bioController,
                        hintText: 'Write a short bio...',
                        icon: Icons.edit_note_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('WORK EMAIL'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _emailController,
                        hintText: 'email@company.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('PHONE NUMBER'),
                      const SizedBox(height: 6),
                      _buildTextFormField(
                        controller: _phoneController,
                        hintText: '+1 (555) 000-0000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Save Profile CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
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
                      'Save Changes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryRust,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7FE)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.titleDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: const Color(0xFF7C8BA1), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
