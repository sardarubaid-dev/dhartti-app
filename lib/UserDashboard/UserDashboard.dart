import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/UserDashboard/Drawer/BottomNavbar.dart';
import 'package:dhartti/UserDashboard/Drawer/UserPanelDrawer.dart';
import 'package:dhartti/UserDashboard/Inquiries/SellerInquiriesScreen.dart';
import 'package:dhartti/UserDashboard/Reviews/SellerReviewsScreen.dart';
import 'package:dhartti/UserDashboard/StoreAdmin/SellerStoreDashboardScreen.dart';
import 'package:dhartti/UserDashboard/UserProjectScreen/UserProjectListScreen.dart';
import 'package:dhartti/UserDashboard/UserPropertyScreen/UserPropertyListScreen.dart';
import 'package:dhartti/UserDashboard/Feature/service.dart';
import 'package:dhartti/UserScreen/ProjectScreen/projectmanagementscreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/service/seller_service.dart';
import 'package:dhartti/UserDashboard/Bids/MyBidsTrackingScreen.dart';
import 'package:dhartti/UserScreen/AllProject.dart';
import 'package:dhartti/UserScreen/VentureFetch.dart';
import 'package:dhartti/UserScreen/DharttiBlog.dart';
import 'package:dhartti/UserScreen/LoanTool/fetch.dart';
import 'package:dhartti/UserScreen/LoanTool/SchemeApplicationsScreen.dart';
import 'package:dhartti/UserScreen/Store/CartScreen.dart';
import 'package:dhartti/UserScreen/Store/MyOrdersScreen.dart';
import 'package:dhartti/CostCalculatorScreen.dart';
import 'package:dhartti/UserScreen/RoleUpgradeFormScreen.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/NotificationScreen.dart';
import 'package:dhartti/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentIndex = 0;
  String username = 'User';
  String userId = '';
  String roleId = '1';
  Map<String, dynamic>? _pendingUpgradeRequest;
  final AuthService _authService = AuthService();
  final SellerService _sellerService = SellerService();

  // Metrics
  int totalProperties = 0;
  int totalProjects = 0;
  int activeListings = 0;
  int forSaleCount = 0;
  int forRentCount = 0;
  int superHotCount = 0;
  int inquiriesCount = 0;
  int reviewsCount = 0;

  // Analytics
  int totalViews = 0;
  int totalCalls = 0;
  int totalWhatsapp = 0;

  // Store
  int storeProducts = 0;
  int storeOrders = 0;
  int pendingOrders = 0;

  bool isLoading = true;

  static const Color dharttiGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }
    await _loadUserData();
    await _loadDashboardData();
    NotificationService().refreshUnreadCount();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('name') ?? 'User';
      userId = prefs.getString('userId') ?? '';
      roleId = prefs.getString('roleId') ?? '1';
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      // 1. Sync latest role & upgrade status from backend
      final statusRes = await _authService.getUpgradeStatus();
      Map<String, dynamic>? pendingReq;
      if (statusRes['has_request'] == true && statusRes['request'] != null) {
        pendingReq = statusRes['request'];
      }

      final prefs = await SharedPreferences.getInstance();
      final freshRoleId = prefs.getString('roleId') ?? roleId;
      roleId = freshRoleId;

      // 2. Fetch stats if Seller or Contractor
      Map<String, dynamic> stats = {};
      if (roleId == '2' || roleId == '3') {
        stats = await _sellerService.fetchDashboardStats();
      }

      if (mounted) {
        setState(() {
          _pendingUpgradeRequest = pendingReq;
          totalProperties = stats['total_properties'] ?? 0;
          totalProjects = stats['total_projects'] ?? 0;
          activeListings = stats['active_listings'] ?? 0;
          forSaleCount = stats['for_sale_count'] ?? 0;
          forRentCount = stats['for_rent_count'] ?? 0;
          superHotCount = stats['super_hot_count'] ?? 0;
          inquiriesCount = stats['inquiries_count'] ?? 0;
          reviewsCount = stats['reviews_count'] ?? 0;

          final analytics = stats['analytics'] as Map<String, dynamic>?;
          totalViews = analytics?['views'] ?? 0;
          totalCalls = analytics?['calls'] ?? 0;
          totalWhatsapp = analytics?['whatsapp'] ?? 0;

          final storeStats = stats['store_stats'] as Map<String, dynamic>?;
          storeProducts = storeStats?['products_count'] ?? 0;
          storeOrders = storeStats?['orders_count'] ?? 0;
          pendingOrders = storeStats?['pending_orders'] ?? 0;

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/nlogo.png',
          height: 38,
          errorBuilder: (_, __, ___) => Text(
            'Dhartti',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: dharttiGreen),
          ),
        ),
        centerTitle: true,
        actions: [
          // Notification Bell with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: dharttiGreen, size: 24),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ).then((_) {
                    NotificationService().refreshUnreadCount();
                  });
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.unreadCountNotifier,
                builder: (context, count, _) {
                  if (count <= 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: dharttiGreen),
            onPressed: () {
              _loadDashboardData();
              NotificationService().refreshUnreadCount();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: UserAdminDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
          : RefreshIndicator(
              color: dharttiGreen,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    _buildHeaderBanner(),
                    const SizedBox(height: 16),

                    // Role Upgrade Section for Normal Users (Buyers)
                    if (roleId == '1') ...[
                      _buildBuyerUpgradeSection(),
                      const SizedBox(height: 18),
                      _buildBuyerQuickTools(),
                      const SizedBox(height: 24),
                    ],

                    if (roleId == '2' || roleId == '3') ...[
                      // Quick Actions
                      _buildQuickActions(),
                      const SizedBox(height: 18),

                      // Metrics Grid (4 core cards)
                      Text(
                        'Business Overview',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      _buildMetricsGrid(),
                      const SizedBox(height: 18),

                      // Engagement Analytics Card
                      _buildEngagementCard(),
                      const SizedBox(height: 18),

                      // Store Management Banner Card
                      _buildStoreManagementCard(),
                      const SizedBox(height: 24),

                      if (roleId == '2') ...[
                        _buildSellerToolsSection(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: (roleId == '2' || roleId == '3')
          ? UserAdminBottomNavBar(
              currentIndex: _currentIndex,
              isContractor: roleId == '3',
              onTap: (index) => setState(() => _currentIndex = index),
            )
          : null,
    );
  }

  Widget _buildBuyerQuickTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buyer Tools & Services',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBuyerToolCard(
                icon: Icons.apartment_rounded,
                title: 'Browse Projects',
                subtitle: 'Find projects',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreens())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBuyerToolCard(
                icon: Icons.group_work_rounded,
                title: 'Joint Ventures',
                subtitle: 'Explore ventures',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinVentureListScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBuyerToolCard(
                icon: Icons.calculate_outlined,
                title: 'Cost Calculator',
                subtitle: 'Estimate expenses',
                color: const Color(0xFFD97706),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CostCalculatorForm())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBuyerToolCard(
                icon: Icons.favorite_rounded,
                title: 'My Favorites',
                subtitle: 'Saved listings',
                color: const Color(0xFFE11D48),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavouriteScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuyerToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerUpgradeSection() {
    if (_pendingUpgradeRequest != null && _pendingUpgradeRequest!['status'] == 'pending') {
      final isPendingSeller = _pendingUpgradeRequest!['requested_role'].toString() == '2';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Pending Approval',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your application to become a ${isPendingSeller ? "Seller" : "Contractor"} is under review by Super Admin. Seller and management features will remain locked until your verification is approved.',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Become a Seller Card (matches Web dashboard.blade.php)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                  Text(
                    'Become a Seller',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.orange, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock real-estate metrics, store administration, and add properties to Dhartti.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleUpgradeFormScreen(targetRole: 2),
                    ),
                  ).then((val) {
                    if (val == true) _loadDashboardData();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.orange, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Become a Contractor Card (matches Web dashboard.blade.php)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
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
                  Text(
                    'Become a Contractor',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38B2AC).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.construction_rounded, color: Color(0xFF38B2AC), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Join ventures and bid on construction projects. Showcase your services to thousands.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleUpgradeFormScreen(targetRole: 3),
                    ),
                  ).then((val) {
                    if (val == true) _loadDashboardData();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upgrade Now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF38B2AC),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFF38B2AC), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    final isContractor = roleId == '3';
    final isBuyer = roleId == '1';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isContractor
              ? [const Color(0xFFB45309), const Color(0xFFD97706)]
              : (isBuyer
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [dharttiGreen, Colors.green.shade700]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isContractor ? Colors.orange : (isBuyer ? Colors.blueGrey : dharttiGreen)).withOpacity(0.25),
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
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  isContractor
                      ? Icons.engineering_rounded
                      : (isBuyer ? Icons.person_rounded : Icons.business_rounded),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $username!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isContractor
                          ? 'Contractor / Builder Hub'
                          : (isBuyer ? 'Buyer Account • Dhartti Portal' : 'Seller Executive Dashboard'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final isContractor = roleId == '3';
    final List<Widget> actionChips = isContractor
        ? [
            _buildActionChip(
              icon: Icons.apartment_rounded,
              label: 'Bid Projects',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreens())),
            ),
            _buildActionChip(
              icon: Icons.group_work_rounded,
              label: 'Bid Ventures',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinVentureListScreen())),
            ),
            _buildActionChip(
              icon: Icons.track_changes_rounded,
              label: 'My Bids',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsTrackingScreen())),
            ),
            _buildActionChip(
              icon: Icons.calculate_outlined,
              label: 'Cost Tool',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CostCalculatorForm())),
            ),
            _buildActionChip(
              icon: Icons.add_shopping_cart_rounded,
              label: 'Store Item',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerStoreDashboardScreen())).then((_) => _loadDashboardData()),
            ),
          ]
        : [
            _buildActionChip(
              icon: Icons.add_home_work_rounded,
              label: 'Add Property',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen())).then((_) => _loadDashboardData()),
            ),
            _buildActionChip(
              icon: Icons.add_business_rounded,
              label: 'Add Project',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProjectScreen())).then((_) => _loadDashboardData()),
            ),
            _buildActionChip(
              icon: Icons.track_changes_rounded,
              label: 'My Bids',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsTrackingScreen())),
            ),
            _buildActionChip(
              icon: Icons.add_shopping_cart_rounded,
              label: 'Store Item',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerStoreDashboardScreen())).then((_) => _loadDashboardData()),
            ),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actionChips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: isContractor ? 84 : 92,
                  child: chip,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: roleId == '3' ? const Color(0xFFB45309) : dharttiGreen),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final isContractor = roleId == '3';
    if (isContractor) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.02,
        children: [
          // 1. Browse Projects to Bid
          _buildMetricCard(
            title: 'Projects to Bid',
            value: 'Browse',
            subtitle: 'Active tenders & projects',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF108224),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreens())),
          ),

          // 2. Joint Ventures to Bid
          _buildMetricCard(
            title: 'Joint Ventures',
            value: 'Explore',
            subtitle: 'Partnership ventures',
            icon: Icons.group_work_rounded,
            color: Colors.blue.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinVentureListScreen())),
          ),

          // 3. My Bids Placed
          _buildMetricCard(
            title: 'My Bids Placed',
            value: 'Tracking',
            subtitle: 'Live status & client replies',
            icon: Icons.track_changes_rounded,
            color: Colors.amber.shade800,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBidsTrackingScreen())),
          ),

          // 4. Store Materials
          _buildMetricCard(
            title: 'Store Materials',
            value: storeProducts.toString(),
            subtitle: 'Materials & supplies listed',
            icon: Icons.storefront_rounded,
            color: Colors.purple.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerStoreDashboardScreen())),
          ),
        ],
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.02,
      children: [
        // 1. My Properties
        _buildMetricCard(
          title: 'My Properties',
          value: totalProperties.toString(),
          subtitle: '$forSaleCount Sale • $forRentCount Rent',
          icon: Icons.home_work_rounded,
          color: const Color(0xFF108224),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPanelPropertyListScreen())),
        ),

        // 2. My Projects
        _buildMetricCard(
          title: 'My Projects',
          value: totalProjects.toString(),
          subtitle: 'Development ventures',
          icon: Icons.business_rounded,
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPanelProjectListScreen())),
        ),

        // 3. Buyer Leads / Inquiries
        _buildMetricCard(
          title: 'Buyer Leads',
          value: inquiriesCount.toString(),
          subtitle: 'Active inquiries',
          icon: Icons.mark_email_unread_outlined,
          color: Colors.amber.shade800,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerInquiriesScreen())),
        ),

        // 4. Property Reviews
        _buildMetricCard(
          title: 'Reviews & Ratings',
          value: reviewsCount.toString(),
          subtitle: 'Customer ratings',
          icon: Icons.star_rate_rounded,
          color: Colors.purple.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerReviewsScreen())),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.grey.shade400),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: dharttiGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Performance & Engagement',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _buildStatItem('Total Views', totalViews.toString(), Icons.visibility_outlined, Colors.blue),
              _buildStatItem('Direct Calls', totalCalls.toString(), Icons.phone_in_talk_outlined, Colors.green),
              _buildStatItem('WhatsApp Leads', totalWhatsapp.toString(), Icons.chat_outlined, const Color(0xFF25D366)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreManagementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dharttiGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: dharttiGreen.withOpacity(0.15),
                child: const Icon(Icons.storefront_rounded, size: 18, color: dharttiGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Management Panel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14.5, color: dharttiGreen),
                    ),
                    Text(
                      'Manage construction inventory and customer orders',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStoreStatBadge('Products Listed', storeProducts.toString()),
              _buildStoreStatBadge('Orders Placed', storeOrders.toString()),
              _buildStoreStatBadge('Pending Delivery', pendingOrders.toString(), isHighlight: pendingOrders > 0),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerStoreDashboardScreen()),
              ).then((_) => _loadDashboardData()),
              icon: const Icon(Icons.launch_rounded, size: 16, color: Colors.white),
              label: Text(
                'Open Store Admin',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStatBadge(String label, String val, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.orange.shade800 : Colors.black87,
              ),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seller Tools & Portals',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: dharttiGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Web Parity',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: dharttiGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.account_balance_outlined,
                title: 'My Schemes',
                subtitle: 'Manage & Add Schemes',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Applications',
                subtitle: 'Manage Loan Leads',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.article_outlined,
                title: 'Blogs & Articles',
                subtitle: 'View & Publish Blogs',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Dharttiblog())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.handshake_outlined,
                title: 'Joint Ventures',
                subtitle: 'Bidding & Ventures',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinVentureListScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Features / Services',
                subtitle: 'Professional services',
                color: const Color(0xFFEA580C),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.shopping_cart_outlined,
                title: 'My Cart',
                subtitle: 'Store shopping cart',
                color: const Color(0xFF059669),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSellerToolCard(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'Track placed orders',
                color: const Color(0xFFDB2777),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSellerToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}