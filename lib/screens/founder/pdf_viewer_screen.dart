import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_preferences_store.dart';

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF525659), // PDF Viewer Slate Dark Grey
      appBar: AppBar(
        backgroundColor: const Color(0xFF323639),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shift_Report_July_2026.pdf',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Print Report',
            icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sending PDF to local network printer...'),
                  backgroundColor: const Color(0xFF006C53),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('PDF file saved to Downloads directory!'),
                  backgroundColor: const Color(0xFFAB3500),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // PDF Document Viewer Canvas
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Header Logo & Title Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'U & ME',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFAB3500),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'WORKPLACE JOY & WELLBEING PLATFORM',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF594139),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7F5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF00AE88)),
                            ),
                            child: Text(
                              'VERIFIED REPORT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF006C53),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFAB3500), thickness: 2),
                      const SizedBox(height: 16),

                      // Document Metadata Block
                      Text(
                        'Employee Shift & Wellbeing Summary Report',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: Column(
                          children: [
                            _buildDocMetaRow('Employee Name', UserPreferencesStore.getUserName()),
                            _buildDocMetaRow('Designation', UserPreferencesStore.getUserRole()),
                            _buildDocMetaRow('Department', UserPreferencesStore.getUserTeam()),
                            _buildDocMetaRow('Reporting Period', 'July 1 - July 28, 2026'),
                            _buildDocMetaRow('Export Date', 'July 28, 2026 at 09:45 PM'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Work Session Hours Table
                      Text(
                        '1. Work Session & Reliability Statistics',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Table(
                        border: TableBorder.all(
                            color: const Color(0xFFDEE1F8), width: 1),
                        children: [
                          TableRow(
                            children: [
                              _buildTableCell('Metric', isHeader: true),
                              _buildTableCell('Recorded Value', isHeader: true),
                              _buildTableCell('Status', isHeader: true),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell('Total Work Hours'),
                              _buildTableCell('164h 30m'),
                              _buildTableCell('On Track'),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell('Avg Daily Hours'),
                              _buildTableCell('8h 12m'),
                              _buildTableCell('Optimal'),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell('Shift Reliability'),
                              _buildTableCell('98.4%'),
                              _buildTableCell('Exemplary'),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell('Breaks Taken'),
                              _buildTableCell('32 Sessions'),
                              _buildTableCell('Healthy'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Appreciation & Peer Morale Summary
                      Text(
                        '2. Peer Recognition & NGL Jar Impact',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF171B2B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDocMetaRow('NGL Appreciation Notes Received', '18 Notes'),
                            _buildDocMetaRow('NGL Appreciation Notes Deposited', '14 Notes'),
                            _buildDocMetaRow('Weekly Hero Nominations Received', '6 Badges'),
                            _buildDocMetaRow('Top Superpower Tags', '#Supportive, #ProblemSolver'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Verification Stamp & Signature Line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 1,
                                color: const Color(0xFF171B2B),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Authorized Signature',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  color: const Color(0xFF594139),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  color: Color(0xFF006C53), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Digitally Verified by U & ME Systems',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF006C53),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFF323639),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('PDF file downloaded to device storage!'),
                          backgroundColor: const Color(0xFFAB3500),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB3500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'Download PDF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Report shared with HR department!'),
                          backgroundColor: const Color(0xFF006C53),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Share with HR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: const Color(0xFF594139),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF171B2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      color: isHeader ? const Color(0xFFF3F2FF) : Colors.transparent,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: isHeader
            ? GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF171B2B),
              )
            : GoogleFonts.beVietnamPro(
                fontSize: 11.5,
                color: const Color(0xFF171B2B),
              ),
      ),
    );
  }
}
