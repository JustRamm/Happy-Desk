import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'compose_ngl_note_screen.dart';
import 'ngl_note_detail_screen.dart';
import '../widgets/jar_icon_widget.dart';
import '../widgets/shredder_icon_widget.dart';
import '../widgets/brand_logo_widget.dart';
import '../widgets/dissolve_stress_modal.dart';
import '../widgets/multi_coffee_reset_modal.dart';
import 'notifications_screen.dart';
import '../services/sound_service.dart';
import '../services/supabase_service.dart';

class JarScreen extends StatefulWidget {
  final bool showBackButton;

  const JarScreen({super.key, this.showBackButton = false});

  @override
  State<JarScreen> createState() => _JarScreenState();
}

class _JarScreenState extends State<JarScreen> {
  bool _todayNoteUnsealed = false;
  int _unopenedNotesCount = 2;

  @override
  void initState() {
    super.initState();
    _loadSupabaseNotes();
  }

  Future<void> _loadSupabaseNotes() async {
    final notes = await SupabaseService.instance.getNglJarMessages();
    if (mounted) {
      setState(() {
        _myOpenedNotes.clear();
        for (var note in notes) {
          _myOpenedNotes.add({
            'id': note['id'] ?? 'note_${_myOpenedNotes.length}',
            'sender': note['is_anonymous'] == true ? 'Anonymous Teammate' : 'Teammate',
            'category': (note['tag'] ?? 'Appreciation').toString().toUpperCase(),
            'message': note['message'] ?? '',
            'date': note['created_at'] != null ? note['created_at'].toString().split('T').first : 'Today',
            'bgColor': const Color(0xFFFFF0EB),
            'categoryColor': const Color(0xFFC84B1A),
            'categoryBg': const Color(0xFFFFE6DD),
          });
        }
      });
    }
  }

  // Loaded Notes (Receiver POV: Only visible to logged in user)
  final List<Map<String, dynamic>> _myOpenedNotes = [];

  void _unsealTodayNote() {
    SoundService.playJarOpenSound();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _RolledPaperUnsealDialog(
        note: _myOpenedNotes[0],
        onUnsealed: () {
          setState(() {
            _todayNoteUnsealed = true;
            if (_unopenedNotesCount > 0) {
              _unopenedNotesCount--;
            }
          });
        },
      ),
    );
  }

  void _openComposeNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComposeNglNoteScreen()),
    );
    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your note was delivered anonymously to their private jar.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. TOP HEADER BAR with Active Color-Filled NGL Jar Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Logo SVG or Back Button if pushed from Home
                  widget.showBackButton
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF171B2B), size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : const BrandLogoWidget(height: 54),

                  // Right Header Action Bar (Notification, Coffee, & Paper Shredder icons)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Color(0xFFAB3500),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Notifications',
                      ),
                      IconButton(
                        onPressed: () => MultiCoffeeResetModal.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: Color(0xFF95416C),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Coffee Break',
                      ),
                      IconButton(
                        onPressed: () => DissolveStressModal.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF0EB),
                            shape: BoxShape.circle,
                          ),
                          child: const ShredderIconWidget(
                            size: 20,
                            state: ShredderState.idle,
                          ),
                        ),
                        tooltip: 'Paper Shredder Stress Vent',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. PRIVACY TAG PILL & TITLE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAE2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppTheme.primaryRust,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Private Joy Vault • Custom For You',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryRust,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'My NGL Appreciation Jar',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.titleDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1 Daily Note unseals per day • Only you can read\nnotes delivered to your private jar.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 24),

              // 3. DAILY NOTE UNSEAL RITUAL CARD (Receiver POV)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Jar Graphic Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8EA9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8EA9)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: JarIconWidget(
                              size: 60,
                              mainColor: Colors.white,
                              lidColor: Color(0xFFC84B1A),
                              liquidColor: Color(0xFFFFD6C7),
                              isFilled: false,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF652F),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              _todayNoteUnsealed
                                  ? 'Opened'
                                  : '$_unopenedNotesCount Waiting',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Unseal Status Title
                    Text(
                      _todayNoteUnsealed
                          ? 'Today\'s Daily Note Unsealed'
                          : '1 Daily Note Ready to Unseal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.titleDark,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _todayNoteUnsealed
                          ? 'Next daily note unseals tomorrow (in 14h 22m).\nSavor today\'s message below!'
                          : 'Each day, 1 note unseals automatically so you can\nsavor every message of appreciation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Unseal Action CTA
                    if (!_todayNoteUnsealed)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _unsealTodayNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC84B1A),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Unseal Today\'s Note',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF047857),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Today\'s Note Unsealed & Saved',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. SENDER POV CTA CARD (Write Note to Teammate or Founder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD6C7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC84B1A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Send an Anonymous Note',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.titleDark,
                                ),
                              ),
                              Text(
                                'Pick a teammate or founder • 100% Private',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _openComposeNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRust,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Write Note to Teammate / Founder',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              const SizedBox(height: 28),


              // 5. RECEIVER POV: MY OPENED NOTES SHOWCASE (Private to Logged In User)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MY OPENED NOTES SHOWCASE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryRust,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Private to You',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Opened Notes List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myOpenedNotes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = _myOpenedNotes[index];
                  return _buildOpenedNoteCard(
                    sender: note['sender'],
                    category: note['category'],
                    message: note['message'],
                    date: note['date'],
                    bgColor: note['bgColor'],
                    categoryColor: note['categoryColor'],
                    categoryBg: note['categoryBg'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NglNoteDetailScreen(
                            recipientName: 'You (Private)',
                            senderName: note['sender'],
                            category: note['category'],
                            message: note['message'],
                            date: note['date'],
                            cardBgColor: note['bgColor'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenedNoteCard({
    required String sender,
    required String category,
    required String message,
    required String date,
    required Color bgColor,
    required Color categoryColor,
    required Color categoryBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_off_outlined,
                                size: 11,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  sender,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.titleDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: categoryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: categoryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.titleDark,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Unsealed: $date',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryRust,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppTheme.primaryRust,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rolled Paper Unsealing Animation Popup Dialog
// ---------------------------------------------------------------------------
class _RolledPaperUnsealDialog extends StatefulWidget {
  final Map<String, dynamic> note;
  final VoidCallback onUnsealed;

  const _RolledPaperUnsealDialog({
    required this.note,
    required this.onUnsealed,
  });

  @override
  State<_RolledPaperUnsealDialog> createState() =>
      _RolledPaperUnsealDialogState();
}

class _RolledPaperUnsealDialogState extends State<_RolledPaperUnsealDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _unrollAnimation;
  late Animation<double> _contentOpacityAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onUnsealed();
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // Unrolling expansion curve (vertical height expansion from rolled scroll to full paper)
    _unrollAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );

    // Content fade-in inside the paper
    _contentOpacityAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final double unrollProgress = _unrollAnimation.value.clamp(0.0, 1.0);
          final double contentOpacity =
              _contentOpacityAnimation.value.clamp(0.0, 1.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Rolled Wooden Scroll Bar Accent
              Transform.scale(
                scaleX: (0.7 + 0.3 * unrollProgress),
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC84B1A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanding Rolled Paper Body
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizeTransition(
                  sizeFactor: _unrollAnimation,
                  axis: Axis.vertical,
                  axisAlignment: 0.0,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 460),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFFBF7,
                      ), // Warm parchment paper background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFE6DD),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFC84B1A,
                          ).withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Opacity(
                        opacity: contentOpacity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Wax Stamp Badge + Recipient Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF0EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.mark_email_read_rounded,
                                        color: Color(0xFFC84B1A),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Unsealed Note For You',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.titleDark,
                                          ),
                                        ),
                                        Text(
                                          '100% Anonymous & Private',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        note['categoryBg'] ??
                                        const Color(0xFFFFE6DD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    note['category'] ?? 'Kindness',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          note['categoryColor'] ??
                                          const Color(0xFFC84B1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(
                              color: Color(0xFFFFE6DD),
                              height: 1,
                            ),
                            const SizedBox(height: 16),

                            // Note Written Message
                            Text(
                              '"${note['message']}"',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.titleDark,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sender & Date Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.visibility_off_outlined,
                                      size: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      note['sender'] ?? 'Anonymous Teammate',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.titleDark,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  note['date'] ?? 'Unsealed Today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // Bottom Button to Store in Private Vault
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC84B1A),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(
                                  'Keep in Private Vault',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Rolled Wooden Scroll Bar Accent
              Transform.scale(
                scaleX: (0.7 + 0.3 * unrollProgress),
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC84B1A),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
