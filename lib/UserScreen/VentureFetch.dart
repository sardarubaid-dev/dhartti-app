import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dhartti/Model/joinVenture.dart';
import 'package:dhartti/service/join_venture_service.dart';
import 'package:dhartti/UserDashboard/Join%20Venture/venture_detail_screen.dart';
import 'package:dhartti/UserDashboard/Join%20Venture/create.dart';

class JoinVentureListScreen extends StatefulWidget {
  const JoinVentureListScreen({Key? key}) : super(key: key);

  @override
  State<JoinVentureListScreen> createState() => _JoinVentureListScreenState();
}

class _JoinVentureListScreenState extends State<JoinVentureListScreen> {
  final JoinVentureService _ventureService = JoinVentureService();
  late Future<List<JoinVenture>> _futureVentures;
  
  int _selectedTab = 0; // 0: All Ventures, 1: My Ventures
  String _searchQuery = '';
  String _selectedIndustry = 'All';

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color darkGreen = Color(0xFF0A5C19);
  static const Color mintBg = Color(0xFFF6FAF7);

  final List<String> _industries = [
    'All',
    'Real Estate',
    'Construction',
    'Commercial',
    'Residential',
    'Infrastructure',
    'Industrial',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshVentures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshVentures() {
    setState(() {
      _futureVentures = _selectedTab == 0
          ? _ventureService.fetchAllVenturesWithBidCounts()
          : _ventureService.fetchVentures();
    });
  }

  List<JoinVenture> _filterVentures(List<JoinVenture> ventures) {
    return ventures.where((v) {
      final matchesQuery = _searchQuery.isEmpty ||
          v.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (v.location != null && v.location!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          v.industry.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesIndustry = _selectedIndustry == 'All' ||
          v.industry.toLowerCase().trim() == _selectedIndustry.toLowerCase().trim();

      return matchesQuery && matchesIndustry;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          'Joint Ventures',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: dharttiGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _refreshVentures,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dharttiGreen,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text(
          'Post Venture',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddJoinVentureScreen()),
          );
          _refreshVentures();
        },
      ),
      body: Column(
        children: [
          // Top Control Panel (Search, Tabs, Category Chips)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      hintText: 'Search ventures, locations, sectors...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Custom Modern Tab Selector
                Row(
                  children: [
                    Expanded(child: _buildTabPill(index: 0, title: 'All Ventures')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTabPill(index: 1, title: 'My Ventures')),
                  ],
                ),

                const SizedBox(height: 10),

                // Industry Chips
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _industries.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final item = _industries[index];
                      final isSelected = _selectedIndustry == item;
                      return InkWell(
                        onTap: () => setState(() => _selectedIndustry = item),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? dharttiGreen : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? dharttiGreen : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEAEAEA)),

          // Venture Cards List
          Expanded(
            child: RefreshIndicator(
              color: dharttiGreen,
              onRefresh: () async => _refreshVentures(),
              child: FutureBuilder<List<JoinVenture>>(
                future: _futureVentures,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: dharttiGreen, strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load ventures',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString().replaceAll('Exception: ', ''),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshVentures,
                              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                              label: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: dharttiGreen),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allVentures = snapshot.data ?? [];
                  final filtered = _filterVentures(allVentures);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(allVentures.isEmpty);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final venture = filtered[index];
                      return _buildVentureCard(venture);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({required int index, required String title}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        if (_selectedTab != index) {
          setState(() {
            _selectedTab = index;
            _refreshVentures();
          });
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? dharttiGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAbsoluteEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dharttiGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_center_rounded, size: 54, color: dharttiGreen),
            ),
            const SizedBox(height: 16),
            Text(
              isAbsoluteEmpty
                  ? (_selectedTab == 0 ? 'No Joint Ventures Available' : 'You Haven\'t Posted Any Ventures')
                  : 'No Matching Ventures Found',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAbsoluteEmpty
                  ? 'Initiate a development or construction venture to connect with verified investors and contractors.'
                  : 'Try clearing your search query or choosing another sector filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddJoinVentureScreen()),
                );
                _refreshVentures();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Text(
                'Post a Venture Now',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentureCard(JoinVenture venture) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VentureDetailScreen(venture: venture),
              ),
            ).then((_) => _refreshVentures());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sector chip + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dharttiGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        venture.industry.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: dharttiGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(venture.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  venture.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        venture.location ?? 'Pakistan (Location flexible)',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  venture.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bottom row: Creator info + Proposals pill + Action Button
                Row(
                  children: [
                    // Creator avatar & name
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: dharttiGreen.withOpacity(0.12),
                      child: Text(
                        (venture.user != null && venture.user!.name.isNotEmpty)
                            ? venture.user!.name[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: dharttiGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venture.user?.name ?? 'Creator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Initiator',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    // Proposals Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: mintBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dharttiGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.handshake_rounded, size: 12, color: dharttiGreen),
                          const SizedBox(width: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${venture.bidsCount} ${venture.bidsCount == 1 ? "Bid" : "Bids"}',
                              style: GoogleFonts.poppins(
                                color: darkGreen,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // View Arrow Button
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dharttiGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
