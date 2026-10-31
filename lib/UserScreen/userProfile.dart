import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/Model/user_model.dart';
import 'package:dhartti/UserScreen/userEditProfile.dart';
import 'package:dhartti/UserScreen/RoleUpgradeFormScreen.dart';
import 'package:dhartti/UserScreen/UpgradeRoleScreen.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/Chat/ChatInboxScreen.dart';
import 'package:dhartti/UserScreen/LoanTool.dart';
import 'package:dhartti/UserScreen/LoanTool/SchemeApplicationsScreen.dart';
import 'package:dhartti/UserDashboard/UserDashboard.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/service/favorite_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  final FavoriteService _favService = FavoriteService();
  User? _user;
  bool _isLoading = true;
  Map<String, dynamic>? _pendingUpgradeRequest;
  int _favCount = 0;
  int _searchCount = 0;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? pendingReq;
      try {
        final statusRes = await _authService.getUpgradeStatus();
        if (statusRes['has_request'] == true && statusRes['request'] != null) {
          pendingReq = statusRes['request'];
        }
      } catch (_) {}

      final user = await _authService.getCurrentUser();
      final favs = await _favService.getFavoriteProperties();
      final searches = await _favService.getSavedSearches();

      if (mounted) {
        setState(() {
          _user = user;
          _pendingUpgradeRequest = pendingReq;
          _favCount = favs.length;
          _searchCount = searches.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your Dhartti account?',
          style: GoogleFonts.poppins(fontSize: 13.5, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'My Account',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: textDark,
              ),
            ),
            Text(
              'Profile & Account Settings',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: dharttiGreen, size: 21),
              tooltip: 'Edit Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                ).then((_) => _loadUserData());
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
          : _user == null
              ? _buildGuestView()
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: dharttiGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          children: [
                            // 1. Luxury Hero Header Card
                            _buildHeroHeader(),

                            // 2. Metrics Bar (Favourites, Searches, Applications)
                            _buildMetricsBar(),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),

                                  // 3. Seller or Contractor Portal / Upgrade Section
                                  _buildRoleSection(),
                                  const SizedBox(height: 16),

                                  // 4. Personal Information Card
                                  _buildPersonalInfoCard(),
                                  const SizedBox(height: 16),

                                  // 5. Quick Account Hub Services
                                  _buildServicesHubCard(),
                                  const SizedBox(height: 24),

                                  // 6. Logout Action Button
                                  OutlinedButton.icon(
                                    onPressed: _confirmLogout,
                                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                                    label: Text(
                                      'Sign Out from Dhartti',
                                      style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                      backgroundColor: Colors.red.withValues(alpha: 0.04),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                 
                                  const SizedBox(height: 120),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, size: 54, color: dharttiGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In to Access Profile',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to manage your listed properties, view applications, saved homes and profile settings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                'Sign In Now',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    Color badgeBg;
    Color badgeColor;
    IconData roleIcon;
    String badgeLabel;

    if (_user!.roleId == 2) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeColor = const Color(0xFFB45309);
      roleIcon = Icons.storefront_rounded;
      badgeLabel = 'Verified Property Seller';
    } else if (_user!.roleId == 3) {
      badgeBg = const Color(0xFFCCFBF1);
      badgeColor = const Color(0xFF0F766E);
      roleIcon = Icons.engineering_rounded;
      badgeLabel = 'Verified Contractor';
    } else {
      badgeBg = const Color(0xFFE0F2FE);
      badgeColor = const Color(0xFF0369A1);
      roleIcon = Icons.verified_user_rounded;
      badgeLabel = 'Verified Member';
    }

    final initial = _user!.name.trim().isNotEmpty ? _user!.name.trim()[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // Avatar Stack
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [dharttiGreen, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dharttiGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: dharttiGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User Name
          Text(
            _user!.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 3),

          // Email
          Text(
            _user!.email,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 14, color: badgeColor),
                const SizedBox(width: 6),
                Text(
                  badgeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            count: '$_favCount',
            label: 'Favourites',
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavouriteScreen(initialTabIndex: 0)),
            ).then((_) => _loadUserData()),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildMetricItem(
            count: '$_searchCount',
            label: 'Saved Searches',
            icon: Icons.bookmark_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavouriteScreen(initialTabIndex: 1)),
            ).then((_) => _loadUserData()),
          ),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          _buildMetricItem(
            count: 'Active',
            label: 'Account Status',
            icon: Icons.verified_rounded,
            color: dharttiGreen,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                  ).then((_) => _loadUserData());
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: dharttiGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.person_outline_rounded, 'Full Name', _user!.name),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.email_outlined, 'Email Address', _user!.email),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            Icons.phone_outlined,
            'Contact Number',
            _user!.contactNumber.isEmpty ? 'Not set yet' : _user!.contactNumber,
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.verified_user_outlined, 'Account Role', _user!.roleName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 18, color: dharttiGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11, color: textMuted),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSection() {
    // If Seller or Contractor
    if (_user!.roleId == 2 || _user!.roleId == 3) {
      final isSeller = _user!.roleId == 2;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSeller ? const Color(0xFFF0FDF4) : const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSeller ? dharttiGreen.withValues(alpha: 0.3) : const Color(0xFF0D9488).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSeller ? Icons.storefront_rounded : Icons.construction_rounded,
                  color: isSeller ? dharttiGreen : const Color(0xFF0D9488),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  isSeller ? 'Seller Dashboard' : 'Contractor Hub',
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isSeller ? dharttiGreen : const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isSeller
                  ? 'Manage your property listings, financing schemes, leads, and store products.'
                  : 'Manage your construction venture bids, contracts, and proposals.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              label: Text(
                'Open Management Portal',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSeller ? dharttiGreen : const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    // Normal User (Buyer) - Upgrade Options
    if (_pendingUpgradeRequest != null && _pendingUpgradeRequest!['status'] == 'pending') {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpgradeRoleScreen()),
            ).then((_) => _loadUserData());
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade Request Pending Review',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your request to become a ${_pendingUpgradeRequest!['requested_role'].toString() == '2' ? 'Seller' : 'Contractor'} is under review. Tap to view status & details.',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD97706), size: 16),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: dharttiGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: dharttiGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Upgrade Your Account',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'List properties, create installment schemes or bid on major construction ventures.',
            style: GoogleFonts.poppins(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleUpgradeFormScreen(targetRole: 2)),
                    ).then((val) {
                      if (val == true) _loadUserData();
                    });
                  },
                  icon: const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFFEA580C)),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Become Seller',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFEA580C)),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEA580C), width: 1.2),
                    backgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.04),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoleUpgradeFormScreen(targetRole: 3)),
                    ).then((val) {
                      if (val == true) _loadUserData();
                    });
                  },
                  icon: const Icon(Icons.handyman_outlined, size: 16, color: Color(0xFF0D9488)),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Become Contractor',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488)),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D9488), width: 1.2),
                    backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.04),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesHubCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(
              'Quick Access & Tools',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
            ),
          ),
          _buildHubTile(
            icon: Icons.assignment_outlined,
            title: 'Scheme & Loan Applications',
            subtitle: 'View submitted applications & financing status',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildHubTile(
            icon: Icons.forum_outlined,
            title: 'Messages & Inquiries',
            subtitle: 'Chat directly with property sellers & buyers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildHubTile(
            icon: Icons.calculate_outlined,
            title: 'Loan & Schemes Calculator',
            subtitle: 'Calculate monthly installment & down payments',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SchemesToolScreen()),
            ),
          ),
          const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
          _buildHubTile(
            icon: Icons.favorite_outline_rounded,
            title: 'Shortlisted Properties',
            subtitle: 'Access all saved favourite homes & plots',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavouriteScreen(initialTabIndex: 0)),
            ).then((_) => _loadUserData()),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(icon, color: dharttiGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: textDark),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
