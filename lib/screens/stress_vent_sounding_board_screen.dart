import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StressVentSoundingBoardScreen extends StatefulWidget {
  const StressVentSoundingBoardScreen({super.key});

  @override
  State<StressVentSoundingBoardScreen> createState() =>
      _StressVentSoundingBoardScreenState();
}

class _StressVentSoundingBoardScreenState
    extends State<StressVentSoundingBoardScreen> {
  final TextEditingController _ventController = TextEditingController();
  String _selectedStressLevel = 'High Deadline Pressure';
  bool _isAnonymousMentorRequested = false;

  final List<Map<String, dynamic>> _stressLevels = [
    {
      'label': 'Mild Workplace Tension',
      'color': const Color(0xFF006C53),
      'bgColor': const Color(0xFFEBF7F5),
      'icon': Icons.sentiment_satisfied_alt_rounded,
    },
    {
      'label': 'High Deadline Pressure',
      'color': const Color(0xFFFF9F1C),
      'bgColor': const Color(0xFFFFF4E5),
      'icon': Icons.speed_rounded,
    },
    {
      'label': 'Burnout Risk',
      'color': const Color(0xFFAB3500),
      'bgColor': const Color(0xFFFFF0EB),
      'icon': Icons.battery_alert_rounded,
    },
    {
      'label': 'Overwhelmed',
      'color': const Color(0xFF95416C),
      'bgColor': const Color(0xFFF3F2FF),
      'icon': Icons.psychology_rounded,
    },
  ];

  @override
  void dispose() {
    _ventController.dispose();
    super.dispose();
  }

  void _dissolveVentNote() {
    if (_ventController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write your thoughts before shredding.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFFAB3500),
        ),
      );
      return;
    }

    _ventController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Vent note dissolved! Your mind is cleared.',
                style: GoogleFonts.beVietnamPro(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006C53),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _requestPeerMentor() {
    setState(() {
      _isAnonymousMentorRequested = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Anonymous peer mentor request submitted. A mentor will reach out shortly.',
                style: GoogleFonts.beVietnamPro(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF95416C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sounding Board & Stress Vent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Confidentiality Guarantee Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF171B2B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AE88).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF00AE88),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Encrypted & Anonymous',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Express feelings without judgment. No logs or identities are stored.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: const Color(0xFFDEE1F8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stress Level Selector
            Text(
              'How are you feeling right now?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _stressLevels.map((lvl) {
                final isSelected = _selectedStressLevel == lvl['label'];
                final color = lvl['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStressLevel = lvl['label'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE4E7FE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          lvl['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lvl['label'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF171B2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Vent Text Area
            Text(
              'Unburden Your Mind',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ventController,
              maxLines: 6,
              style: GoogleFonts.beVietnamPro(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Write down what is stressing you today (e.g. deadline anxiety, team friction, exhaustion). Write freely...',
                hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE4E7FE)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action 1: Shred & Dissolve Vent
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _dissolveVentNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB3500),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                label: Text(
                  'Shred & Dissolve Vent Paper',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Action 2: Peer Mentor Sounding Board Option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDEE1F8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent_rounded,
                          color: Color(0xFF95416C), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Request Peer Mentor Sounding Board',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prefer to talk with a compassionate listener? Request a quiet 1-on-1 text chat with an assigned workplace peer mentor.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: const Color(0xFF594139),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isAnonymousMentorRequested ? null : _requestPeerMentor,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF95416C), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: Icon(
                        _isAnonymousMentorRequested
                            ? Icons.check_rounded
                            : Icons.mark_email_read_rounded,
                        color: const Color(0xFF95416C),
                        size: 18,
                      ),
                      label: Text(
                        _isAnonymousMentorRequested
                            ? 'Request Pending • Mentor Assigned'
                            : 'Request Anonymous Peer Mentor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF95416C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
