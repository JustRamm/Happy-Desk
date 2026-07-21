import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_preferences_store.dart';

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
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  int _selectedAvatarIndex = 0;

  final List<String> _avatarOptions = [
    'assets/brand/app_icon.png',
    'assets/brand/1.png',
  ];

  final List<String> _statusVibes = [
    'In Deep Focus',
    'Available & Collaborative',
    'On 5-Min Desk Stretch',
    'WFH Coffee Break',
  ];
  String _selectedStatusVibe = 'Available & Collaborative';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserPreferencesStore.getUserName());
    _roleController = TextEditingController(text: UserPreferencesStore.getUserRole());
    _bioController = TextEditingController(text: UserPreferencesStore.getUserBio());
    _workplaceController = TextEditingController(text: UserPreferencesStore.getCompany());
    _emailController = TextEditingController(text: 'alex.m@happy-desk.com');
    _phoneController = TextEditingController(text: '+1 (555) 234-5678');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _workplaceController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await UserPreferencesStore.setUserName(_nameController.text.trim());
      await UserPreferencesStore.setUserRole(_roleController.text.trim());
      await UserPreferencesStore.setUserBio(_bioController.text.trim());
      await UserPreferencesStore.setCompany(_workplaceController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
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
                  onTap: () {
                    setState(() {
                      _selectedAvatarIndex = (_selectedAvatarIndex + 1) % _avatarOptions.length;
                    });
                  },
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
                              child: Image.asset(
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

                      _buildFieldLabel('WORK VIBE STATUS'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatusVibe,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.titleDark),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.titleDark,
                            ),
                            items: _statusVibes.map((vibe) {
                              return DropdownMenuItem<String>(
                                value: vibe,
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 16, color: AppTheme.primaryRust),
                                    const SizedBox(width: 8),
                                    Text(vibe),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatusVibe = val);
                              }
                            },
                          ),
                        ),
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
