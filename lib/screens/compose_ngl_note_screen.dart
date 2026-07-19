import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ComposeNglNoteScreen extends StatefulWidget {
  const ComposeNglNoteScreen({super.key});

  @override
  State<ComposeNglNoteScreen> createState() => _ComposeNglNoteScreenState();
}

class _ComposeNglNoteScreenState extends State<ComposeNglNoteScreen> {
  final _messageController = TextEditingController();
  String _selectedRecipient = 'Alex Miller (Founder & CEO)';
  String _selectedCategory = 'Kindness';
  int _selectedColorIndex = 0;
  bool _isAnonymous = true;

  final List<String> _recipients = [
    'Alex Miller (Founder & CEO)',
    'Sarah Chen (Design Lead)',
    'Rownok Rahman (Product Manager)',
    'David Kim (Senior Engineer)',
    'Whole Team (Community Jar)',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Kindness', 'color': const Color(0xFFFF652F), 'bg': const Color(0xFFFFEBE6)},
    {'name': 'Growth', 'color': const Color(0xFF10B981), 'bg': const Color(0xFFE6F7F0)},
    {'name': 'Teamwork', 'color': const Color(0xFF7C3AED), 'bg': const Color(0xFFF0EBFE)},
    {'name': 'Excellence', 'color': const Color(0xFFD97706), 'bg': const Color(0xFFFFF7ED)},
  ];

  final List<Color> _cardColors = [
    const Color(0xFFFFF0EB), // Soft Coral Peach
    const Color(0xFFF0EBFE), // Soft Lavender
    const Color(0xFFE6F7F0), // Soft Mint
    const Color(0xFFFFF7ED), // Soft Warm Gold
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitNote() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write a note before dropping it into the jar.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryRust,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appreciation note added to the NGL Jar!',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _cardColors[_selectedColorIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8), // Warm soft background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.titleDark,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Write Appreciation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.titleDark,
                        ),
                      ),
                    ],
                  ),

                  // Tag Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRust.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NGL Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryRust,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section 1: Recipient Selector
              _buildSectionLabel('RECIPIENT'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRecipient,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.titleDark),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.titleDark,
                    ),
                    items: _recipients.map((recipient) {
                      return DropdownMenuItem<String>(
                        value: recipient,
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 18, color: AppTheme.primaryRust),
                            const SizedBox(width: 10),
                            Text(recipient),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedRecipient = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Privacy Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF047857), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% Anonymous • Delivered privately to their jar.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Category Selector
              _buildSectionLabel('CATEGORY'),
              const SizedBox(height: 8),
              Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['name'];
                  final Color color = cat['color'];
                  final Color bg = cat['bg'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? bg : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? color : const Color(0xFFE5E7EB),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat['name'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? color : AppTheme.titleDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Section 3: Card Theme Palette
              _buildSectionLabel('CARD THEME'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_cardColors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _cardColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryRust : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryRust)
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Section 4: Dynamic Note Card Input Container
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('YOUR NOTE'),
                  GestureDetector(
                    onTap: _showAiAssistModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: Color(0xFF95416C),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI Magic Assist',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF95416C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To: $_selectedRecipient',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.titleDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryRust,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      maxLength: 250,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.titleDark,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Write a kind, encouraging, or appreciative note for your teammate...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade500,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _isAnonymous ? 'From: Anonymous Teammate' : 'From: You',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 5: Anonymous Switch Tile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRust.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.visibility_off_outlined,
                        color: AppTheme.primaryRust,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send Anonymously',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.titleDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your identity will be hidden in the jar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      activeThumbColor: AppTheme.primaryRust,
                      onChanged: (val) => setState(() => _isAnonymous = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitNote,
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
                        'Drop Note into Jar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.send_rounded, size: 18, color: Colors.white),
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

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryRust,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showAiAssistModal() {
    final aiPrompts = [
      {
        'title': 'Teamwork & Crunch Time',
        'prompt':
            'Huge thanks for stepping in and helping me finish our sprint deliverables under crunch time! Couldn\'t have done it without your support.',
        'category': 'Teamwork',
      },
      {
        'title': 'Kindness & Mentorship',
        'prompt':
            'I really appreciate how patient and encouraging you were during our team sync today. Your guidance made a huge difference!',
        'category': 'Kindness',
      },
      {
        'title': 'Problem Solving & Innovation',
        'prompt':
            'Not gonna lie, your brilliant quick thinking on the backend architectural issue saved our entire deployment sprint this week!',
        'category': 'Excellence',
      },
      {
        'title': 'Daily Energy & Positivity',
        'prompt':
            'Thank you for bringing so much warmth, positivity, and uplifting energy to our workplace every single day!',
        'category': 'Growth',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF95416C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Gratitude & Praise Writer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.titleDark,
                          ),
                        ),
                        Text(
                          'Select an AI appreciation prompt to auto-draft your note',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...aiPrompts.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: const Color(0xFFFAF8FF),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _messageController.text = item['prompt']!;
                          _selectedCategory = item['category']!;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'AI appreciation note generated!',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: const Color(0xFF95416C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF95416C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['prompt']!,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12.5,
                                color: AppTheme.titleDark,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
