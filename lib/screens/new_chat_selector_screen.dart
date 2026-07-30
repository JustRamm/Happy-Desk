import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'direct_chat_screen.dart';

class NewChatSelectorScreen extends StatefulWidget {
  const NewChatSelectorScreen({super.key});

  @override
  State<NewChatSelectorScreen> createState() => _NewChatSelectorScreenState();
}

class _NewChatSelectorScreenState extends State<NewChatSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _allDirectory = [
    {
      'name': 'Alex Miller',
      'role': 'Product Designer',
      'team': 'Design',
      'isOnline': true,
      'avatar': '',
    },
    {
      'name': 'Sarah Chen',
      'role': 'Lead Engineer',
      'team': 'Engineering',
      'isOnline': true,
      'avatar': '',
    },
    {
      'name': 'David Kim',
      'role': 'Frontend Architect',
      'team': 'Engineering',
      'isOnline': false,
      'avatar': '',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Community Lead',
      'team': 'Product',
      'isOnline': false,
      'avatar': '',
    },
    {
      'name': 'Elena Rostova',
      'role': 'Customer Success Lead',
      'team': 'Product',
      'isOnline': true,
      'avatar': '',
    },
    {
      'name': 'Mary Jane',
      'role': 'Product Manager',
      'team': 'Product',
      'isOnline': true,
      'avatar': '',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();

    final filteredDirectory = _allDirectory.where((person) {
      final nameMatches = (person['name'] as String).toLowerCase().contains(query);
      final roleMatches = (person['role'] as String).toLowerCase().contains(query);

      if (_activeFilter == 'Online Now') {
        return (nameMatches || roleMatches) && person['isOnline'] == true;
      } else if (_activeFilter != 'All') {
        return (nameMatches || roleMatches) && person['team'] == _activeFilter;
      }
      return nameMatches || roleMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF171B2B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Start New Message',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF171B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Header Box
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E7FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFAB3500),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search by teammate name or role...',
                            hintStyle: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Online Now', 'Engineering', 'Design', 'Product'].map((filter) {
                      final isSelected = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF171B2B),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFAB3500),
                          backgroundColor: const Color(0xFFFAF8FF),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFAB3500) : const Color(0xFFE4E7FE),
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _activeFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Contact List
          Expanded(
            child: filteredDirectory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 48,
                          color: Color(0xFF8D7168),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No teammates found matching search',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF171B2B),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDirectory.length,
                    itemBuilder: (context, index) {
                      final person = filteredDirectory[index];
                      final isOnline = person['isOnline'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE4E7FE)),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DirectChatScreen(teammate: person),
                              ),
                            );
                          },
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFFFF0EB),
                                child: ((person['avatar'] as String? ?? '').startsWith('http') ||
                                        ((person['avatar'] as String? ?? '').isNotEmpty && File(person['avatar']).existsSync()))
                                    ? ClipOval(
                                        child: (person['avatar'] as String).startsWith('http')
                                            ? Image.network(person['avatar'], fit: BoxFit.cover, width: 44, height: 44)
                                            : Image.file(File(person['avatar']), fit: BoxFit.cover, width: 44, height: 44),
                                      )
                                    : Text(
                                        (person['name'] as String? ?? '?').isNotEmpty
                                            ? (person['name'] as String)[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFAB3500),
                                        ),
                                      ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00AE88),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            person['name'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF171B2B),
                            ),
                          ),
                          subtitle: Text(
                            '${person['role']} • ${person['team']}',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: const Color(0xFF594139),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF0EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Color(0xFFAB3500),
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
