import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/constants.dart';
import 'package:dhartti/Model/superproperty_model.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/Model/project_model.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:dhartti/Model/Blog.dart';
import 'package:dhartti/service/blog_service.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/service/favorite_service.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/userProfile.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:dhartti/UserScreen/ProjectDetailPage.dart';
import 'package:dhartti/UserScreen/AllProject.dart';
import 'package:dhartti/UserScreen/VentureFetch.dart';
import 'package:dhartti/UserScreen/DharttiBlog.dart';
import 'package:dhartti/UserScreen/BlogDetailScreen.dart';
import 'package:dhartti/UserScreen/PropertyTrend.dart';
import 'package:dhartti/area_guide.dart';
import 'package:dhartti/area_converter.dart';
import 'package:dhartti/UserScreen/LoanTool.dart';
import 'package:dhartti/UserScreen/Tools/PlotFinder.dart';
import 'package:dhartti/CostCalculatorScreen.dart';
import 'package:dhartti/UserScreen/Chat/ChatInboxScreen.dart';
import 'package:dhartti/UserScreen/NotificationScreen.dart';
import 'package:dhartti/service/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  bool isGuest = true;

  // Cached Futures to prevent screen reloading / flickering on state changes
  late Future<List<PropertySuperAdmin>> _propertiesFuture;
  late Future<List<Project>> _projectsFuture;
  late Future<List<Blog>> _blogsFuture;

  static const Color primaryGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    _propertiesFuture = PropertyService().fetchPropertyBySuperAdmin();
    _projectsFuture = ProjectService().fetchProjectsBySuperAdmin();
    _blogsFuture = BlogService().fetchBlogs();
    NotificationService().refreshUnreadCount();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isGuest = prefs.getString('token') == null;
      });
    }
  }

  void _showGuestLoginDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Login Required",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(
              "Log In",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of Dhartti?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Price on Inquiry';
    double val = 0;
    if (amount is num) {
      val = amount.toDouble();
    } else {
      val = double.tryParse(amount.toString().replaceAll(',', '').trim()) ?? 0;
    }
    if (val <= 0) return 'Price on Inquiry';

    if (val >= 10000000) {
      return 'PKR ${(val / 10000000).toStringAsFixed(2)} Crore';
    } else if (val >= 100000) {
      return 'PKR ${(val / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return 'PKR ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  String _formatBudgetRange(Project p) {
    final min = p.budgetRangeMin;
    final max = p.budgetRangeMax;
    if (min > 0 && max > 0) {
      return '${_formatCurrency(min)} - ${_formatCurrency(max)}';
    } else if (min > 0) {
      return 'From ${_formatCurrency(min)}';
    } else if (max > 0) {
      return 'Up to ${_formatCurrency(max)}';
    }
    return 'Price on Inquiry';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 70,
        leading: Builder(
          builder: (context) => Center(
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                color: const Color(0xFFF8FAFC),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF1E293B), size: 20),
                onPressed: () {
                  if (BottomNavBarScreen.scaffoldKey.currentState != null) {
                    BottomNavBarScreen.scaffoldKey.currentState!.openDrawer();
                  } else {
                    try {
                      Scaffold.of(context).openDrawer();
                    } catch (_) {}
                  }
                },
              ),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Image.asset(
          'assets/images/nlogo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(
            'Dhartti',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          // Notifications Bell Button
          Container(
            height: 38,
            width: 38,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              color: const Color(0xFFF8FAFC),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: primaryGreen, size: 20),
                  tooltip: 'Notifications',
                  onPressed: () {
                    if (isGuest) {
                      _showGuestLoginDialog('Please log in to view your notifications.');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      ).then((_) {
                        NotificationService().refreshUnreadCount();
                      });
                    }
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unreadCountNotifier,
                  builder: (context, count, _) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
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
          ),
          // Quick Chat Button (Always accessible)
          Container(
            height: 38,
            width: 38,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
              color: const Color(0xFFF8FAFC),
            ),
            child: IconButton(
              icon: const Icon(Icons.forum_outlined, color: primaryGreen, size: 19),
              tooltip: 'Messages & Chat',
              onPressed: () {
                if (isGuest) {
                  _showGuestLoginDialog('Please log in to chat with sellers, agents, and contractors.');
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatInboxScreen()));
                }
              },
            ),
          ),
          if (isGuest)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login, size: 16, color: Colors.white),
                  label: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF1E293B), size: 19),
                    tooltip: 'My Profile',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 38,
                  width: 38,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 18),
                    tooltip: 'Logout',
                    onPressed: () => _confirmLogout(),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Hero Section with the beloved Filter Widget
            _buildHeroBanner(),

            const SizedBox(height: 24),

            // Top Cities & Locations
            _buildTopLocations(),

            const SizedBox(height: 28),

            // Featured Properties Slider
            _buildFeaturedProperties(),

            const SizedBox(height: 28),

            // Popular Projects Slider
            _buildPopularProjects(),

            const SizedBox(height: 28),

            // Smart Real Estate Tools & Calculators
            _buildToolsAndServices(),

            const SizedBox(height: 28),

            // Why Choose Dhartti? (Trust & Benefits)
            _buildDharttiFeatures(),

            const SizedBox(height: 28),

            // Latest News & Property Insights
            _buildLatestBlogs(),

            const SizedBox(height: 28),

            // Joint Ventures Banner
            _buildJoinVenturesCTA(),

            const SizedBox(height: 36),

            // Footer
            _buildFooter(), const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODERN HERO BANNER WITH FILTER WIDGET
  // ==========================================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGreen.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: primaryGreen),
                const SizedBox(width: 5),
                Text(
                  '100% Verified Real Estate Portal',
                  style: GoogleFonts.poppins(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Clean Heading
          Text(
            'Find Your Perfect Property In Pakistan',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 4),

          // Subtitle
          Text(
            'Browse verified houses, plots, and mega projects with zero hidden markups.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // The beloved Web Style Main Filter
          const HomeFilterWidget(),

          const SizedBox(height: 16),

          // Trust Highlights Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrustItem(Icons.home_work_outlined, '10,000+ Listings'),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildTrustItem(Icons.verified_user_outlined, 'Direct Sellers'),
                Container(height: 24, width: 1, color: Colors.grey.shade300),
                _buildTrustItem(Icons.shield_outlined, '0% Hidden Fees'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String label) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primaryGreen),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP LOCATIONS
  // ==========================================
  Widget _buildTopLocations() {
    final serverBase = AppConstants.baseUrl.replaceAll('/api', '');

    final Map<String, String> cityLandmarks = {
      'Islamabad': '$serverBase/assets/images/islamabad.jpg',
      'Lahore': '$serverBase/assets/images/lahore.jpg',
      'Karachi': '$serverBase/assets/images/karachi.jpg',
      'Rawalpindi': '$serverBase/assets/images/rawalpindi.jpg',
      'Faisalabad': '$serverBase/assets/images/faislabad.jpg',
      'Peshawar': '$serverBase/assets/images/peshawar.jpg',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Top Cities',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    'Find prime properties across Pakistan',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BottomNavBarScreen(initialIndex: 1),
                    ),
                  );
                },
                child: Text('See All', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: FutureBuilder<List<PropertySuperAdmin>>(
            future: _propertiesFuture,
            builder: (context, snapshot) {
              final properties = snapshot.data ?? [];
              Map<String, int> cityCounts = {
                'Islamabad': 0,
                'Lahore': 0,
                'Karachi': 0,
                'Rawalpindi': 0,
                'Faisalabad': 0,
                'Peshawar': 0,
              };

              for (var p in properties) {
                if (p.city != null && p.city!.isNotEmpty) {
                  cityCounts[p.city!] = (cityCounts[p.city!] ?? 0) + 1;
                }
              }

              final cities = cityCounts.keys.toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final count = cityCounts[city] ?? 0;
                  final imgUrl = cityLandmarks[city] ?? '';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BottomNavBarScreen(
                            initialIndex: 1,
                            initialCity: city,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 125,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF1E293B),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imgUrl.isNotEmpty
                                ? Image.network(
                                    imgUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: primaryGreen.withOpacity(0.2),
                                      child: const Icon(Icons.location_city, color: Colors.white70, size: 36),
                                    ),
                                  )
                                : Container(
                                    color: primaryGreen.withOpacity(0.2),
                                    child: const Icon(Icons.location_city, color: Colors.white70, size: 36),
                                  ),
                          ),
                          // Dark gradient overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.85),
                                ],
                                stops: const [0.35, 1.0],
                              ),
                            ),
                          ),
                          // Content at bottom
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  count > 0 ? '$count Properties' : 'Explore City',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FEATURED PROPERTIES SLIDER
  // ==========================================
  Widget _buildFeaturedProperties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured Properties',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    'Hand-picked verified listings for you',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BottomNavBarScreen(initialIndex: 1),
                    ),
                  );
                },
                child: Text('View All', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 310,
          child: FutureBuilder<List<PropertySuperAdmin>>(
            future: _propertiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No featured properties available right now.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                );
              }

              final properties = snapshot.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: properties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return _buildModernPropertyCard(properties[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernPropertyCard(PropertySuperAdmin property) {
    final rawImg = property.imagePath ?? '';
    final imageUrl = rawImg.isNotEmpty ? PropertyService.formatPropertyImageUrl(rawImg) : '';
    final isRent = (property.purpose ?? 'Sale').toLowerCase() == 'rent';

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (property.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(propertyId: property.id!),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 155,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2));
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.home_work_outlined, color: Colors.grey, size: 40),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.home_work_outlined, color: Colors.grey, size: 40),
                          ),
                  ),
                ),
                // Purpose Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRent ? Colors.blue.shade700 : primaryGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isRent ? 'FOR RENT' : 'FOR SALE',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (property.isHot == true || property.isSuperHot == true)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HOT',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    _formatCurrency(property.price),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Title
                  Text(
                    property.title ?? 'Dhartti Verified Property',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.city ?? 'Pakistan',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Specs Row (Beds, Baths, Area)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecItem(Icons.bed_outlined, '${property.bedrooms ?? 3} Beds'),
                      _buildSpecItem(Icons.bathtub_outlined, '${property.bathrooms ?? 2} Baths'),
                      _buildSpecItem(Icons.square_foot_outlined, '${property.areaSize ?? 5} ${property.areaUnit ?? 'Marla'}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ==========================================
  // POPULAR PROJECTS
  // ==========================================
  Widget _buildPopularProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending Projects',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    'Commercial and housing mega schemes',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreens()));
                },
                child: Text('View All', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<Project>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No projects found.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                );
              }

              final projects = snapshot.data!;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final imageUrl = project.image.isNotEmpty ? project.image : '';

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(projectId: project.id),
                        ),
                      );
                    },
                    child: Container(
                      width: 270,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Container(
                                  height: 135,
                                  width: double.infinity,
                                  color: const Color(0xFFF1F5F9),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (c, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2));
                                          },
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.apartment_rounded, color: Colors.grey, size: 40),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.apartment_rounded, color: Colors.grey, size: 40),
                                        ),
                                ),
                              ),
                              if (project.city.isNotEmpty)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, size: 10, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          project.city,
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.title,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (project.developerTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${project.developerTitle}',
                                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 11.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatBudgetRange(project),
                                    style: GoogleFonts.poppins(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SMART REAL ESTATE TOOLS
  // ==========================================
  Widget _buildToolsAndServices() {
    final List<Map<String, dynamic>> tools = [
      {
        'title': 'Plot Finder',
        'desc': 'Interactive sector maps',
        'icon': Icons.travel_explore_rounded,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen())),
      },
      {
        'title': 'Cost Calculator',
        'desc': 'Grey & finishing costs',
        'icon': Icons.architecture_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => CostCalculatorForm())),
      },
      {
        'title': 'Home Loan',
        'desc': 'Monthly markup schemes',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemesToolScreen())),
      },
      {
        'title': 'Area Converter',
        'desc': 'Marla, Kanal, Sq. Ft.',
        'icon': Icons.straighten_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => AreaConverterScreen())),
      },
      {
        'title': 'Area Guide',
        'desc': 'Societies & sectors',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF0891B2),
        'bg': const Color(0xFFECFEFF),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => AreaGuideScreen())),
      },
      {
        'title': 'Property Trends',
        'desc': 'Price growth insights',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFE11D48),
        'bg': const Color(0xFFFFF1F2),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyTrend())),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Real Estate Tools',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              Text(
                'Everything you need to calculate, convert, and plan',
                style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 76,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return InkWell(
                onTap: tool['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tool['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tool['title'] as String,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool['desc'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WHY CHOOSE DHARTTI? (TRUST & VALUE)
  // ==========================================
  Widget _buildDharttiFeatures() {
    final features = [
      {
        'title': '100% Verified Records',
        'desc': 'All property titles and society NOCs pass multi-layer validation before listing.',
        'icon': Icons.verified_user_rounded,
        'color': primaryGreen,
      },
      {
        'title': 'Direct Owner Connect',
        'desc': 'Chat directly with certified sellers and contractors with transparent price talks.',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': Colors.blue.shade700,
      },
      {
        'title': 'Transparent Bidding',
        'desc': 'Contractors and buyers submit real-time bids with clear terms and timelines.',
        'icon': Icons.gavel_rounded,
        'color': Colors.purple.shade700,
      },
      {
        'title': 'Market Data & Insights',
        'desc': 'Accurate construction cost tools, area guides, and localized price trend indices.',
        'icon': Icons.analytics_outlined,
        'color': Colors.amber.shade800,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Choose Dhartti?',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      'Pakistan’s most trusted real estate ecosystem',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((f) {
            final isChatFeature = f['title'] == 'Direct Owner Connect';
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (isChatFeature) {
                  if (isGuest) {
                    _showGuestLoginDialog('Please log in to chat with sellers, agents, and contractors.');
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatInboxScreen()));
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (f['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f['icon'] as IconData, size: 16, color: f['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                f['title'] as String,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                              ),
                              if (isChatFeature) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue.shade200, width: 0.8),
                                  ),
                                  child: Text(
                                    'Open Chat',
                                    style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f['desc'] as String,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade600, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================
  // LATEST NEWS & BLOGS
  // ==========================================
  Widget _buildLatestBlogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Insights & Blogs',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    'Trends, advisory, and buying guides',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const Dharttiblog()));
                },
                child: Text('View All', style: GoogleFonts.poppins(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Blog>>(
            future: _blogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryGreen));
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No blog articles available right now.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                );
              }

              final blogs = snapshot.data!.take(5).toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: blogs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final blog = blogs[index];
                  final imageUrl = BlogService.formatImageUrl(blog.blogImage1);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
                      );
                    },
                    child: Container(
                      width: 230,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Container(
                              height: 115,
                              width: double.infinity,
                              color: const Color(0xFFF1F5F9),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2));
                                      },
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.newspaper_rounded, color: Colors.grey, size: 36),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.newspaper_rounded, color: Colors.grey, size: 36),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    blog.tagsList.isNotEmpty ? blog.tagsList.first : '#RealEstate',
                                    style: GoogleFonts.poppins(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  blog.blogHeading1.isNotEmpty ? blog.blogHeading1 : 'Property Market Update',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // JOIN VENTURES CTA SECTION
  // ==========================================
  Widget _buildJoinVenturesCTA() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF108224), Color(0xFF0B631B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Co-Invest in Joint Ventures',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Partner with certified developers and participate in verified high-yield projects.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinVentureListScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    elevation: 0,
                  ),
                  child: Text(
                    'Explore Ventures',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_outlined, size: 48, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FOOTER SECTION
  // ==========================================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apartment_rounded, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Dhartti',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your trusted verified real estate portal in Pakistan.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(
            '© 2026 Dhartti. All rights reserved.',
            style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HOME FILTER WIDGET (BELOVED FILTER SYSTEM)
// ==========================================
class HomeFilterWidget extends StatefulWidget {
  const HomeFilterWidget({Key? key}) : super(key: key);

  @override
  State<HomeFilterWidget> createState() => _HomeFilterWidgetState();
}

class _HomeFilterWidgetState extends State<HomeFilterWidget> {
  String _selectedPurpose = 'rent'; // 'rent', 'sell', 'project'
  String _selectedType = 'All Types';
  String _selectedCity = 'All Cities';
  bool _showAdvancedFilters = false;
  String _selectedBeds = 'Any';
  String _selectedBaths = 'Any';
  String _selectedCurrency = 'PKR (Rs)';
  String _selectedAreaUnit = 'Square Feet';
  double _priceRange = 50000000; // 5.00 Crore max
  double _areaSize = 10000; // 10,000 sq ft max

  static const Color primaryGreen = Color(0xFF108224);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Purpose Tabs: For Rent, For Sale, Project
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPurposeTab("For Rent", Icons.home_outlined, 'rent'),
                const SizedBox(width: 8),
                _buildPurposeTab("For Sale", Icons.vpn_key_outlined, 'sell'),
                const SizedBox(width: 8),
                _buildPurposeTab("Project", Icons.apartment_outlined, 'project'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Primary Dropdowns: Type & City
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdownContainer(
                  badgeText: "Type",
                  badgeIcon: Icons.trending_up,
                  value: _selectedType,
                  items: const [
                    'All Types',
                    'House',
                    'Flat',
                    'Plot',
                    'Commercial',
                    'Penthouse',
                    'Office',
                    'Shop',
                    'Room',
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterDropdownContainer(
                  badgeText: "City",
                  badgeIcon: Icons.location_on,
                  value: _selectedCity,
                  items: const [
                    'All Cities',
                    'Lahore',
                    'Karachi',
                    'Islamabad',
                    'Rawalpindi',
                    'Faisalabad',
                    'Peshawar',
                    'Multan',
                    'Gujranwala',
                    'Quetta',
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCity = val!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Action Row: Advanced Filter Button & Search Now Button
          Row(
            children: [
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showAdvancedFilters ? primaryGreen : primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryGreen,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAdvancedFilters ? Icons.close : Icons.tune,
                          color: _showAdvancedFilters ? Colors.white : primaryGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showAdvancedFilters ? "Hide Filters" : "Advanced Filter",
                          style: GoogleFonts.poppins(
                            color: _showAdvancedFilters ? Colors.white : primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () => _executeFilterSearch(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Search Now",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _saveFilterSearch(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryGreen, width: 1.2),
                  ),
                  child: const Icon(Icons.bookmark_add_outlined, color: primaryGreen, size: 20),
                ),
              ),
            ],
          ),

          // 4. Advanced Filter Collapsible Section
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),

            // Beds & Baths Row
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdownContainer(
                    badgeText: "Beds",
                    badgeIcon: Icons.bed_outlined,
                    value: _selectedBeds,
                    items: const ['Any', '1', '2', '3', '4', '5', '5+'],
                    onChanged: (val) {
                      setState(() {
                        _selectedBeds = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterDropdownContainer(
                    badgeText: "Baths",
                    badgeIcon: Icons.bathtub_outlined,
                    value: _selectedBaths,
                    items: const ['Any', '1', '2', '3', '4', '5+'],
                    onChanged: (val) {
                      setState(() {
                        _selectedBaths = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Currency & Area Unit Row
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdownContainer(
                    badgeText: "Currency",
                    badgeIcon: Icons.attach_money,
                    value: _selectedCurrency,
                    items: const ['PKR (Rs)', 'USD (\$)'],
                    onChanged: (val) {
                      setState(() {
                        _selectedCurrency = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFilterDropdownContainer(
                    badgeText: "Area Unit",
                    badgeIcon: Icons.square_foot,
                    value: _selectedAreaUnit,
                    items: const ['Square Feet', 'Marla', 'Kanal', 'Sq. Yd.'],
                    onChanged: (val) {
                      setState(() {
                        _selectedAreaUnit = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price Range Slider & Quick Presets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sell_outlined, size: 14, color: primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            "Max Price",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1E293B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatPriceLabel(_priceRange),
                        style: GoogleFonts.poppins(color: primaryGreen, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryGreen,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: primaryGreen,
                      overlayColor: primaryGreen.withOpacity(0.15),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 0,
                      max: _selectedPurpose == 'rent' ? 1000000 : 50000000,
                      value: _priceRange > (_selectedPurpose == 'rent' ? 1000000 : 50000000)
                          ? (_selectedPurpose == 'rent' ? 1000000 : 50000000)
                          : _priceRange,
                      onChanged: (val) {
                        setState(() {
                          _priceRange = val;
                        });
                      },
                    ),
                  ),
                  // Quick Presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: (_selectedPurpose == 'rent'
                          ? [
                              {'label': '< 30k', 'val': 30000.0},
                              {'label': '< 50k', 'val': 50000.0},
                              {'label': '< 1 Lac', 'val': 100000.0},
                              {'label': '< 2.5 Lac', 'val': 250000.0},
                              {'label': 'Any', 'val': 1000000.0},
                            ]
                          : [
                              {'label': '< 50 Lac', 'val': 5000000.0},
                              {'label': '< 1 Cr', 'val': 10000000.0},
                              {'label': '< 2.5 Cr', 'val': 25000000.0},
                              {'label': '< 5 Cr', 'val': 50000000.0},
                              {'label': 'Any', 'val': 50000000.0},
                            ]).map((preset) {
                        bool isSelected = (_priceRange == preset['val']);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _priceRange = preset['val'] as double;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryGreen : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryGreen : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                preset['label'] as String,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Area Size Slider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.aspect_ratio_outlined, size: 14, color: primaryGreen),
                      const SizedBox(width: 6),
                      Text(
                        "Area Size",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryGreen,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: primaryGreen,
                      overlayColor: primaryGreen.withOpacity(0.15),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 0,
                      max: 10000,
                      value: _areaSize,
                      onChanged: (val) {
                        setState(() {
                          _areaSize = val;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Min: 0", style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(
                        "Max: ${_areaSize.toInt()} $_selectedAreaUnit",
                        style: GoogleFonts.poppins(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPriceLabel(double val) {
    if (val >= 10000000) {
      return "${(val / 10000000).toStringAsFixed(2)} Crore";
    } else if (val >= 100000) {
      return "${(val / 100000).toStringAsFixed(1)} Lac";
    } else if (val >= 1000) {
      return "${(val / 1000).toStringAsFixed(0)}k PKR";
    } else {
      return "${val.toInt()} PKR";
    }
  }

  Widget _buildPurposeTab(String title, IconData icon, String value) {
    bool isSelected = _selectedPurpose == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPurpose = value;
          if (value == 'rent') {
            if (_priceRange > 1000000) _priceRange = 500000;
          } else {
            if (_priceRange <= 1000000) _priceRange = 50000000;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdownContainer({
    required String badgeText,
    required IconData badgeIcon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 9, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
              style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 12.5, fontWeight: FontWeight.w600),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 12.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFilterSearch(BuildContext context) async {
    List<String> parts = [];
    if (_selectedCity != 'All Cities') parts.add(_selectedCity);
    if (_selectedType != 'All Types') parts.add(_selectedType);
    if (_selectedPurpose != 'all') parts.add('For ${_selectedPurpose.toUpperCase()}');
    if (_selectedBeds != 'Any') parts.add('$_selectedBeds Beds');
    if (parts.isEmpty) parts.add("Home Search");
    final String defaultTitle = parts.join(' • ');

    double? passedPrice;
    if (_selectedPurpose == 'rent') {
      if (_priceRange < 1000000) passedPrice = _priceRange;
    } else {
      if (_priceRange < 50000000) passedPrice = _priceRange;
    }

    await FavoriteService().saveSearch(
      title: defaultTitle,
      city: _selectedCity == 'All Cities' ? null : _selectedCity,
      purpose: _selectedPurpose == 'all' ? null : _selectedPurpose,
      propertyType: _selectedType == 'All Types' ? null : _selectedType,
      beds: _selectedBeds == 'Any' ? null : _selectedBeds,
      baths: _selectedBaths == 'Any' ? null : _selectedBaths,
      maxPrice: passedPrice,
      maxArea: _areaSize < 10000 ? _areaSize : null,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.bookmark_added_rounded, color: primaryGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Search '$defaultTitle' saved!",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "VIEW",
            textColor: primaryGreen,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavouriteScreen(initialTabIndex: 1)),
              );
            },
          ),
        ),
      );
    }
  }

  void _executeFilterSearch(BuildContext context) {
    if (_selectedPurpose == 'project') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectListScreens()),
      );
    } else {
      double? passedPrice;
      if (_selectedPurpose == 'rent') {
        if (_priceRange < 1000000) passedPrice = _priceRange;
      } else {
        if (_priceRange < 50000000) passedPrice = _priceRange;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavBarScreen(
            initialIndex: 1,
            initialPurpose: _selectedPurpose,
            initialCity: _selectedCity == 'All Cities' ? null : _selectedCity,
            initialPropertyType: _selectedType == 'All Types' ? null : _selectedType,
            initialBeds: _selectedBeds == 'Any' ? null : _selectedBeds,
            initialBaths: _selectedBaths == 'Any' ? null : _selectedBaths,
            initialMaxPrice: passedPrice,
            initialMaxArea: _areaSize < 10000 ? _areaSize : null,
          ),
        ),
      );
    }
  }
}