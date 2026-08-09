import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../widgets/founder_leave_approvals_modal.dart';

class FounderAnalyticsScreen extends StatefulWidget {
  const FounderAnalyticsScreen({super.key});

  @override
  State<FounderAnalyticsScreen> createState() =>
      _FounderAnalyticsScreenState();
}

class _FounderAnalyticsScreenState
    extends State<FounderAnalyticsScreen> {
  String _selectedDateFilter = 'Today';
  String _selectedStatusFilter = 'All';

  bool _isLoading = false;
  List<Map<String, dynamic>> _employeeSessions = [];

  final List<String> _dateFilterOptions = ['Today', 'Yesterday', 'This Week'];
  final List<String> _statusFilterOptions = [
    'All',
    'Clocked In',
    'Clocked Out',
    'On Break',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeamWorkAnalytics();
  }

  Future<void> _loadTeamWorkAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await SupabaseService.instance.getCompanyTeammates();
      if (mounted) {
        setState(() {
          _employeeSessions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSessions {
    return _employeeSessions.where((emp) {
      final isClockedIn = emp['is_clocked_in'] == true;
      final isOnBreak = emp['is_on_break'] == true;

      if (_selectedStatusFilter == 'Clocked In') {
        if (!isClockedIn || isOnBreak) return false;
      } else if (_selectedStatusFilter == 'Clocked Out') {
        if (isClockedIn) return false;
      } else if (_selectedStatusFilter == 'On Break') {
        if (!isOnBreak) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _employeeSessions
        .where((e) => e['is_clocked_in'] == true && e['is_on_break'] != true)
        .length;
    final totalMembers = _employeeSessions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Team Member Hours & Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFAB3500)),
            onPressed: _loadTeamWorkAnalytics,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFD5C7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Clocked-In',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B2600),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$activeCount / $totalMembers Working',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFAB3500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avg Shift Hours',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF594139),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '7.5 Hours / Day',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pending Employee Leave Approvals Banner Card
              GestureDetector(
                onTap: () => FounderLeaveApprovalsModal.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.beach_access_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee Leave Approvals Portal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Review pending leave requests & approve/reject',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFF78350F),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Date Filters
              Text(
                'Date View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _dateFilterOptions.map((opt) {
                    final selected = _selectedDateFilter == opt;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(opt),
                        selected: selected,
                        selectedColor: const Color(0xFFAB3500),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(0xFF594139),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedDateFilter = opt;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Status Filters
              Text(
                'Filter Teammates Status',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF171B2B),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilterOptions.map((opt) {
                    final selected = _selectedStatusFilter == opt;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(opt),
                        selected: selected,
                        selectedColor: const Color(0xFF171B2B),
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(0xFF594139),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedStatusFilter = opt;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Teammate Work Session List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Employee Shift Records (${_filteredSessions.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF171B2B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFFAB3500)),
                  ),
                )
              else if (_filteredSessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Center(
                    child: Text(
                      'No work session records matching selected filter.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: const Color(0xFF8D7168),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredSessions.length,
                  itemBuilder: (context, index) {
                    final emp = _filteredSessions[index];
                    final name = emp['name'] ?? 'Employee';
                    final role = emp['job_title'] ?? emp['department'] ?? 'Team Member';
                    final avatar = emp['avatar_url'] as String? ?? '';
                    final isClockedIn = emp['is_clocked_in'] == true;
                    final isOnBreak = emp['is_on_break'] == true;
                    final location = emp['location_name'] ?? 'Office HQ';

                    String statusText = 'Clocked Out';
                    Color statusColor = const Color(0xFF6B7280);
                    Color statusBg = const Color(0xFFF3F4F6);

                    if (isClockedIn && isOnBreak) {
                      statusText = 'On Break';
                      statusColor = const Color(0xFFD97706);
                      statusBg = const Color(0xFFFEF3C7);
                    } else if (isClockedIn) {
                      statusText = 'Clocked In (Active)';
                      statusColor = const Color(0xFF047857);
                      statusBg = const Color(0xFFD1FAE5);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE4E7FE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFFFF0EB),
                                child: (avatar.startsWith('http') || (avatar.isNotEmpty && File(avatar).existsSync()))
                                    ? ClipOval(
                                        child: avatar.startsWith('http')
                                            ? Image.network(avatar, fit: BoxFit.cover, width: 48, height: 48)
                                            : Image.file(File(avatar), fit: BoxFit.cover, width: 48, height: 48),
                                      )
                                    : Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFAB3500),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF171B2B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      role,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12.5,
                                        color: const Color(0xFF594139),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFAB3500)),
                              const SizedBox(width: 6),
                              Text(
                                isClockedIn ? 'Clocked In at 9:15 AM' : 'Shift Ended at 5:30 PM',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF171B2B),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '8h 15m Logged',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tracked Location: $location',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: const Color(0xFF8D7168),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
