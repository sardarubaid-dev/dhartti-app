import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Auth_Screens/register.dart';
import 'package:dhartti/service/SchemeService.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeApplicationsScreen extends StatefulWidget {
  final int? specificSchemeId;
  final String? specificSchemeName;

  const SchemeApplicationsScreen({
    super.key,
    this.specificSchemeId,
    this.specificSchemeName,
  });

  @override
  State<SchemeApplicationsScreen> createState() => _SchemeApplicationsScreenState();
}

class _SchemeApplicationsScreenState extends State<SchemeApplicationsScreen> {
  static const Color primaryGreen = Color(0xFF108224);

  bool _isLoading = true;
  bool _isGuest = false;
  List<Map<String, dynamic>> _applications = [];
  String _selectedStatus = 'All'; // All, pending, approved, rejected
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isGuest = false;
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data;
      if (widget.specificSchemeId != null) {
        data = await SchemeService.getSchemeApplications(widget.specificSchemeId!);
      } else {
        data = await SchemeService.getAllUserSchemeApplications();
      }
      setState(() {
        _applications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeStatus(int applicationId, String newStatus) async {
    try {
      final success = await SchemeService.updateApplicationStatus(applicationId, newStatus);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application marked as ${newStatus.toUpperCase()}'),
            backgroundColor: newStatus == 'approved'
                ? primaryGreen
                : (newStatus == 'rejected' ? Colors.red : Colors.orange),
          ),
        );
        _fetchApplications();
      } else {
        throw Exception('Server returned non-200');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    return _applications.where((app) {
      final status = (app['status'] ?? 'pending').toString().toLowerCase();
      final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus.toLowerCase();

      final name = (app['name'] ?? '').toString().toLowerCase();
      final city = (app['city'] ?? '').toString().toLowerCase();
      final phone = (app['number'] ?? '').toString().toLowerCase();
      final schemeName = ((app['scheme']?['scheme_name'] ?? '')).toString().toLowerCase();

      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          name.contains(q) ||
          city.contains(q) ||
          phone.contains(q) ||
          schemeName.contains(q);

      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(' ', '').replaceAll('-', '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String applicantName, String schemeName) async {
    var clean = phone.replaceAll(' ', '').replaceAll('-', '');
    if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    }
    final message = Uri.encodeComponent(
      'Hello $applicantName, regarding your application for $schemeName on Dhartti Portal.',
    );
    final uri = Uri.parse('https://wa.me/$clean?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.specificSchemeName != null
        ? '${widget.specificSchemeName} Applications'
        : 'My Applications';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryGreen),
            onPressed: _fetchApplications,
          ),
        ],
      ),
      body: _isGuest
          ? _buildGuestState()
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                      : RefreshIndicator(
                          onRefresh: _fetchApplications,
                          color: primaryGreen,
                          child: _filteredList.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  itemCount: _filteredList.length,
                                  itemBuilder: (ctx, idx) => _buildApplicationCard(_filteredList[idx]),
                                ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by applicant, phone, city...',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: primaryGreen,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No applications found',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Applications you have submitted or received leads for your schemes will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In Required',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged into your Dhartti account to view and manage scheme applications.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ).then((_) => _fetchApplications());
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sign In to Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ).then((_) => _fetchApplications());
              },
              child: Text(
                'Don’t have an account? Register',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final int id = int.tryParse(app['id']?.toString() ?? '0') ?? 0;
    final String name = app['name'] ?? 'Applicant';
    final String email = app['email'] ?? 'No email';
    final String phone = app['number']?.toString() ?? 'N/A';
    final String cnic = app['cnic']?.toString() ?? 'N/A';
    final String city = app['city'] ?? 'N/A';
    final String salary = app['salary']?.toString() ?? 'N/A';
    final String status = (app['status'] ?? 'pending').toString().toLowerCase();
    final String schemeName = app['scheme']?['scheme_name'] ?? 'Scheme #$id';
    final String createdAt = (app['created_at'] ?? '').toString().split('T').first;

    final bool isReceivedLead = app['is_received_lead'] == true ||
        app['is_received_lead'] == 1 ||
        app['is_received_lead'] == '1';
    final bool isSubmittedByMe = app['is_submitted_by_me'] == true ||
        app['is_submitted_by_me'] == 1 ||
        app['is_submitted_by_me'] == '1';

    Color badgeColor;
    String badgeText;
    if (status == 'approved') {
      badgeColor = primaryGreen;
      badgeText = 'APPROVED';
    } else if (status == 'rejected') {
      badgeColor = const Color(0xFFDC2626);
      badgeText = 'REJECTED';
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeText = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Scheme name + Tag & Status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    schemeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryGreen),
                  ),
                ),
                if (isSubmittedByMe && !isReceivedLead) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Text(
                      'My Application',
                      style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                    ),
                  ),
                ] else if (isReceivedLead) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      'Received Lead',
                      style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF7E22CE)),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Applicant Name + Date
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'Applied: $createdAt',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Detail Grid / Key values
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.phone_outlined, 'Phone', phone)),
                Expanded(child: _buildInfoItem(Icons.location_city_outlined, 'City', city)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildInfoItem(Icons.badge_outlined, 'CNIC', cnic)),
                Expanded(child: _buildInfoItem(Icons.payments_outlined, 'Salary / Income', 'PKR $salary')),
              ],
            ),
            if (email.isNotEmpty && email != 'No email') ...[
              const SizedBox(height: 8),
              _buildInfoItem(Icons.email_outlined, 'Email', email),
            ],

            const SizedBox(height: 14),
            // Actions Row
            if (isSubmittedByMe && !isReceivedLead) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'approved'
                          ? Icons.check_circle_rounded
                          : (status == 'rejected' ? Icons.cancel_rounded : Icons.hourglass_top_rounded),
                      size: 18,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status == 'approved'
                            ? 'Approved by financing provider'
                            : (status == 'rejected'
                                ? 'Application rejected by financing provider'
                                : 'Application under review by financing provider'),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (phone != 'N/A' && phone.isNotEmpty) ...[
                    IconButton.filledTonal(
                      icon: const Icon(Icons.call_rounded, size: 18, color: primaryGreen),
                      style: IconButton.styleFrom(backgroundColor: primaryGreen.withValues(alpha: 0.12)),
                      onPressed: () => _makePhoneCall(phone),
                      tooltip: 'Call Applicant',
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF0D9488)),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12)),
                      onPressed: () => _openWhatsApp(phone, name, schemeName),
                      tooltip: 'WhatsApp Applicant',
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Approve / Reject Actions (for Scheme Owner / Seller)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'approved') ...[
                          ElevatedButton.icon(
                            onPressed: () => _changeStatus(id, 'approved'),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.white),
                            label: Text(
                              'Approve',
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (status != 'rejected') ...[
                          OutlinedButton.icon(
                            onPressed: () => _changeStatus(id, 'rejected'),
                            icon: const Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFDC2626)),
                            label: Text(
                              'Reject',
                              style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFDC2626)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
