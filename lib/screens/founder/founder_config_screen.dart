import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service.dart';
import '../../services/user_preferences_store.dart';
import '../../theme/app_theme.dart';

class FounderConfigScreen extends StatefulWidget {
  const FounderConfigScreen({super.key});

  @override
  State<FounderConfigScreen> createState() => _FounderConfigScreenState();
}

class _FounderConfigScreenState extends State<FounderConfigScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _industryController = TextEditingController();

  String _selectedCompanySize = '1-10 employees';
  String _companyCode = '';
  String? _companyId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapsLinkController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      // 1. Fetch profile to get company ID
      final profile = await SupabaseService.instance.client
          .from('profiles')
          .select('company_id')
          .eq('id', user.id)
          .single();

      _companyId = profile['company_id'] as String?;
      if (_companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch company record details
      final comp = await SupabaseService.instance.client
          .from('companies')
          .select()
          .eq('id', _companyId!)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = comp['name']?.toString() ?? '';
          _addressController.text = comp['hq_address']?.toString() ?? comp['hq_location']?.toString() ?? '';
          _latController.text = comp['hq_latitude']?.toString() ?? '';
          _lngController.text = comp['hq_longitude']?.toString() ?? '';
          _mapsLinkController.text = comp['hq_google_maps_link']?.toString() ?? '';
          _industryController.text = comp['industry']?.toString() ?? '';
          _selectedCompanySize = comp['company_size']?.toString() ?? '1-10 employees';
          _companyCode = comp['company_code']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading founder config data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _autoDetectCoordinates() async {
    try {
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        final request = await Geolocator.requestPermission();
        if (request != LocationPermission.always && request != LocationPermission.whileInUse) {
          _showError('Location permission is required to auto-detect coordinates.');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.best,
                timeLimit: const Duration(seconds: 30),
                forceLocationManager: false,
              )
            : AppleSettings(
                accuracy: LocationAccuracy.best,
                activityType: ActivityType.other,
                timeLimit: const Duration(seconds: 30),
              ),
      );
      if (!mounted) return;

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates auto-detected successfully!'),
          backgroundColor: Color(0xFF00AE88),
        ),
      );
    } catch (e) {
      _showError('Could not detect coordinates: $e');
    }
  }

  Future<void> _saveConfig() async {
    if (_companyId == null) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final mapsLink = _mapsLinkController.text.trim();
    final industry = _industryController.text.trim();

    if (name.isEmpty) {
      _showError('Company Name cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Update remote DB
      await SupabaseService.instance.client.from('companies').update({
        'name': name,
        'hq_address': address,
        'hq_location': address,
        'hq_latitude': lat,
        'hq_longitude': lng,
        'hq_google_maps_link': mapsLink,
        'industry': industry,
        'company_size': _selectedCompanySize,
      }).eq('id', _companyId!);

      // 2. Update local preferences
      await UserPreferencesStore.setCompanyDetails(
        companyName: name,
        hqLocation: address,
        industry: industry,
        companySize: _selectedCompanySize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company HQ configuration saved!'),
            backgroundColor: Color(0xFF00AE88),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving company config: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppTheme.primaryRust,
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: Text(
          'HQ Workspace Settings',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRust,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile/HQ code header
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryRust, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Join Code',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _companyCode.isNotEmpty ? _companyCode : 'Generating...',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.titleDark,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(_companyCode, 'Company Join Code'),
                            icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryRust),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Forms
                    Text(
                      'COMPANY PROFILE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('Company Name'),
                    _buildTextField(_nameController, 'e.g. Acme Corp', Icons.business_rounded),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Company Domain / Industry'),
                    _buildTextField(_industryController, 'e.g. Software & Tech', Icons.domain_rounded),
                    const SizedBox(height: 20),

                    // Geofencing coordinates settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GEOFENCE HQ BOUNDARIES',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1.1,
                          ),
                        ),
                        InkWell(
                          onTap: _autoDetectCoordinates,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location_rounded, color: AppTheme.primaryRust, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Auto-detect GPS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryRust,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel('HQ Address (Full Address)'),
                    _buildTextField(_addressController, 'e.g. 123 Main St, New York, USA', Icons.location_on_rounded),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Latitude'),
                              _buildTextField(
                                _latController,
                                'e.g. 40.7128',
                                Icons.map_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Longitude'),
                              _buildTextField(
                                _lngController,
                                'e.g. -74.0060',
                                Icons.map_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Google Maps Reference Link'),
                    _buildTextField(_mapsLinkController, 'https://maps.google.com/?q=...', Icons.link_rounded),
                    const SizedBox(height: 24),

                    _buildFieldLabel('Company Size'),
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
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? AppTheme.primaryRust : const Color(0xFFE4E7FE)),
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
                    const SizedBox(height: 36),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRust,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0DDD9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Save HQ Configurations',
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.titleDark,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7FE)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
