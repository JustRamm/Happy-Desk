import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does NGL Jar anonymity work?',
      'answer':
          'All notes submitted into the NGL Jar are 100% encrypted. Unless you explicitly choose to sign your name, your identity is completely hidden from both teammates and workspace managers.',
    },
    {
      'question': 'How are Weekly Heroes selected?',
      'answer':
          'Heroes are nominated peer-to-peer by teammates using superpower tags (#Supportive, #ProblemSolver, #LifeSaver). Nominations reset every Sunday night, and top nominees earn community badges.',
    },
    {
      'question': 'How does Clock-In location logging work?',
      'answer':
          'When clocking in, you select your location (e.g. HQ Floor 3 or Home Office). It logs the duration and sends an optional team broadcast so colleagues know when you are available.',
    },
    {
      'question': 'Can I integrate with Google Workspace?',
      'answer':
          'Yes! U & ME integrates with Google Workspace (Calendar, Sheets, Classroom, and Chat) for seamless calendar scheduling and team notifications.',
    },
    {
      'question': 'What is the Stress Vent Shredder?',
      'answer':
          'The Stress Vent Shredder is a private, encrypted digital shredder. You can type out workplace frustrations or stress, tap "Shred Vent", and watch your text dissolve permanently without leaving a trace.',
    },
    {
      'question': 'How do Virtual Coffee Breaks work?',
      'answer':
          'Coffee Breaks allow you to schedule 10-minute micro 1-on-1s with colleagues. You can pick an icebreaker prompt and automatically invite them via calendar.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return q.contains(query) || a.contains(query);
    }).toList();

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
          'Help & Support Center',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.titleDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF95416C), Color(0xFFC0528A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF95416C).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How can we help you?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Search our knowledge base or explore frequently asked questions about U & ME features.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search Bar Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.titleDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search help topics or questions...',
                    hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7C8BA1), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // FAQ Section Label
              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryRust,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // FAQ Tiles List
              if (filteredFaqs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'No matching help topics found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...filteredFaqs.map((faq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E7FE)),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        faq['question']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.titleDark,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['answer']!,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AppTheme.titleDark,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Contact Support Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD6C7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRust,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still have questions?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.titleDark,
                            ),
                          ),
                          Text(
                            'Our workplace support team is here 24/7.',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Support ticket initiated! We will contact you shortly.',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white),
                            ),
                            backgroundColor: AppTheme.primaryRust,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRust,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(
                        'Contact',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
