import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/coffee/leave_history_screen.dart';
import '../services/supabase_service.dart';
import '../services/user_preferences_store.dart';

class ApplyLeaveModal extends StatefulWidget {
  const ApplyLeaveModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const ApplyLeaveModal(),
      ),
    );
  }

  @override
  State<ApplyLeaveModal> createState() => _ApplyLeaveModalState();
}

class _ApplyLeaveModalState extends State<ApplyLeaveModal> {
  String _selectedType = 'Casual Leave';
  final List<String> _leaveTypes = const [
    'Casual Leave',
    'Sick Leave',
    'Annual Rest',
    'Personal Emergency',
  ];

  final TextEditingController _reasonController = TextEditingController();
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime.now().add(const Duration(days: 2)),
    end: DateTime.now().add(const Duration(days: 3)),
  );

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDateRange != null
        ? '${_selectedDateRange!.start.month}/${_selectedDateRange!.start.day} – ${_selectedDateRange!.end.month}/${_selectedDateRange!.end.day}'
        : 'Select Dates';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle & Title Row
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E7FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF7F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.beach_access_rounded,
                          color: Color(0xFF006C53),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Apply for Leave',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF8D7168)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // View Leave Balance & History Log Tile Inside Menu (Employee only)
              if (UserPreferencesStore.getUserRole() != 'founder' &&
                  !UserPreferencesStore.getIsLeader()) ...[
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveHistoryScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF7F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00AE88).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded,
                              color: Color(0xFF006C53), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Leave Balance & History Log',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF006C53),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Check remaining quotas & past request status',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11.5,
                                  color: const Color(0xFF4A4E69),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Color(0xFF006C53)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Leave Type Chips
              Text(
                'Leave Category',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A4E69),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _leaveTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Text(type),
                    labelStyle: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF2D3142),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF006C53),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF006C53)
                            : const Color(0xFFE4E7FE),
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date Range Selection Box
              Text(
                'Leave Duration',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A4E69),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Color(0xFF006C53), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        dateText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded,
                          color: Color(0xFF8D7168)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reason Input Textfield
              Text(
                'Reason for Leave (Optional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A4E69),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E7FE)),
                ),
                child: TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    color: const Color(0xFF2D3142),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Family event, medical appointment...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: const Color(0xFF8D7168),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final dates = dateText;
                    if (_selectedDateRange != null) {
                      await SupabaseService.instance.submitLeaveRequest(
                        leaveType: _selectedType,
                        startDate: _selectedDateRange!.start,
                        endDate: _selectedDateRange!.end,
                        reason: _reasonController.text.trim(),
                      );
                    }
                    UserPreferencesStore.addLeaveRequest(
                        '$_selectedType ($dates) - Pending HR Approval');
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$_selectedType application submitted to HR for approval!',
                                style: GoogleFonts.beVietnamPro(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF006C53),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C53),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Submit Application for Approval',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
