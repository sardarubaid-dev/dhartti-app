import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/UserDashboard/UserDashboard.dart';
import 'package:dhartti/UserScreen/RoleUpgradeFormScreen.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/service/auth_service.dart';

class UpgradeRoleScreen extends StatefulWidget {
  const UpgradeRoleScreen({super.key});

  @override
  State<UpgradeRoleScreen> createState() => _UpgradeRoleScreenState();
}

class _UpgradeRoleScreenState extends State<UpgradeRoleScreen> {
  static const Color primaryGreen = Color(0xFF108224);
  static const Color darkSlate = Color(0xFF161E2D);
  static const Color accentAmber = Color(0xFFF59E0B);

  final AuthService _authService = AuthService();
  Map<String, dynamic>? _pendingRequest;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus({bool showFeedback = false}) async {
    if (showFeedback) setState(() => _isRefreshing = true);
    try {
      final res = await _authService.getUpgradeStatus();
      if (mounted) {
        setState(() {
          _pendingRequest = res['request'];
          _isLoading = false;
          _isRefreshing = false;
        });

        if (showFeedback) {
          final status = _pendingRequest?['status'];
          if (status == 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Congratulations! Your application has been approved.'),
                backgroundColor: primaryGreen,
              ),
            );
          } else if (status == 'pending') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application is still under review by Super Admin.'),
                backgroundColor: accentAmber,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status refreshed.')),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _pendingRequest?['status']?.toString().toLowerCase();
    final bool isPending = status == 'pending';
    final bool isApproved = status == 'approved';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPending
              ? 'Application Status'
              : (isApproved ? 'Account Upgraded' : 'Upgrade Account'),
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            tooltip: 'Refresh Status',
            onPressed: _isRefreshing ? null : () => _checkStatus(showFeedback: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: isApproved
                  ? _buildApprovedView()
                  : (isPending ? _buildPendingView() : _buildRoleSelectionView()),
            ),
    );
  }

  // ===========================================================================
  // 1. PENDING VIEW (STRICTLY NO FORM OR UPGRADE BUTTONS CAN BE TAPPED)
  // ===========================================================================
  Widget _buildPendingView() {
    final reqRole = _pendingRequest!['requested_role'];
    final bool isSeller = reqRole == 2 || reqRole.toString() == '2';
    final roleName = isSeller ? 'Seller' : 'Contractor';
    final dynamic details = _pendingRequest!['details'];

    String? firmOrAgency;
    String? city;
    String? cnic;
    String? specialization;

    if (details is Map) {
      firmOrAgency = details['agency_name'] ?? details['firm_name'] ?? details['company_name'];
      city = details['city'];
      cnic = details['cnic'];
      specialization = details['specialization'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentAmber.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: accentAmber, size: 36),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentAmber.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'UNDER REVIEW BY ADMIN',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFCD34D),
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$roleName Verification Application',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application has been received and is currently being evaluated by Dhartti Super Admin. You cannot submit another request until this is processed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade300,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Timeline / Progress Indicator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification Progress',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: darkSlate),
              ),
              const SizedBox(height: 16),
              _buildProgressStep(
                title: 'Application Submitted',
                desc: 'Your request & credentials were submitted successfully.',
                isDone: true,
                isActive: false,
              ),
              _buildProgressStep(
                title: 'Super Admin Review',
                desc: 'Admin is reviewing your credentials & documents.',
                isDone: false,
                isActive: true,
              ),
              _buildProgressStep(
                title: '$roleName Dashboard Access',
                desc: 'Dashboard & tools will unlock immediately once approved.',
                isDone: false,
                isActive: false,
                isLast: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Submitted Application Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 20, color: primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Submitted Application Details',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14.5, color: darkSlate),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildDetailRow('Applied Role', roleName),
              if (firmOrAgency != null && firmOrAgency.isNotEmpty)
                _buildDetailRow(isSeller ? 'Agency Name' : 'Firm Name', firmOrAgency),
              if (specialization != null && specialization.isNotEmpty)
                _buildDetailRow('Specialization', specialization),
              if (city != null && city.isNotEmpty)
                _buildDetailRow('City', city),
              if (cnic != null && cnic.isNotEmpty)
                _buildDetailRow('CNIC', cnic),
              _buildDetailRow('Status', 'Pending Approval', statusColor: accentAmber),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Refresh & Return Buttons
        ElevatedButton.icon(
          onPressed: _isRefreshing ? null : () => _checkStatus(showFeedback: true),
          icon: _isRefreshing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          label: Text(
            'Check / Refresh Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.home_outlined, size: 18, color: darkSlate),
          label: Text(
            'Explore Platform as Buyer',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5, color: darkSlate),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. APPROVED VIEW
  // ===========================================================================
  Widget _buildApprovedView() {
    final reqRole = _pendingRequest?['requested_role'];
    final bool isSeller = reqRole == 2 || reqRole.toString() == '2';
    final roleName = isSeller ? 'Seller' : 'Contractor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Congratulations!',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account has been verified and upgraded to $roleName by the Super Admin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            'Open $roleName Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. ROLE SELECTION VIEW (WHEN NOT PENDING)
  // ===========================================================================
  Widget _buildRoleSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Text(
          'Elevate Your Experience',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Apply for a verified Seller or Contractor role. Applications are submitted directly to the Super Admin for swift review.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Seller Upgrade Card
        _buildRoleCard(
          title: 'Become a Seller',
          roleTag: 'Real Estate & Properties',
          icon: Icons.storefront_rounded,
          accentColor: const Color(0xFFEA580C),
          desc:
              'Post and manage your property listings, create installment schemes, track analytics, and manage client inquiries directly.',
          features: [
            'Direct property & project listings',
            'Lead analytics & client inquiry inbox',
            'Create & manage installment schemes',
          ],
          buttonText: 'Apply for Seller Account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleUpgradeFormScreen(targetRole: 2)),
            ).then((_) => _checkStatus());
          },
        ),

        const SizedBox(height: 20),

        // Contractor Upgrade Card
        _buildRoleCard(
          title: 'Become a Contractor',
          roleTag: 'Construction & Joint Ventures',
          icon: Icons.construction_rounded,
          accentColor: const Color(0xFF0D9488),
          desc:
              'Bid on major joint venture projects, showcase verified building services, and collaborate with verified land owners across Pakistan.',
          features: [
            'Bid on construction projects & ventures',
            'Interactive bid tracking & negotiations',
            'Access construction materials store',
          ],
          buttonText: 'Apply for Contractor Account',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleUpgradeFormScreen(targetRole: 3)),
            ).then((_) => _checkStatus());
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String roleTag,
    required IconData icon,
    required Color accentColor,
    required String desc,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkSlate,
                      ),
                    ),
                    Text(
                      roleTag,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: GoogleFonts.poppins(fontSize: 12.8, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...features.map((feat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feat,
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkSlate,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required String title,
    required String desc,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
  }) {
    final Color circleColor = isDone
        ? primaryGreen
        : (isActive ? accentAmber : Colors.grey.shade300);
    final IconData icon = isDone
        ? Icons.check_rounded
        : (isActive ? Icons.hourglass_top_rounded : Icons.circle_outlined);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? primaryGreen : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isActive ? darkSlate : (isDone ? primaryGreen : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600)),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: statusColor ?? darkSlate,
            ),
          ),
        ],
      ),
    );
  }
}
