import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Auth_Screens/register.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideItem> _slides = [
    OnboardingSlideItem(
      category: "EXPLORE PROPERTIES",
      title: "Find Your Dream Home\nAcross Pakistan",
      subtitle:
          "Browse thousands of verified houses, residential plots, and commercial spaces with live prices across 42+ cities.",
      mainIcon: Icons.apartment_rounded,
      badgeLeftIcon: Icons.verified_rounded,
      badgeLeftColor: Color(0xFF0284C7),
      badgeLeftText: "100% Verified",
      badgeRightIcon: Icons.location_on_rounded,
      badgeRightColor: Color(0xFF059669),
      badgeRightText: "42+ Cities Active",
      trustPills: [
        "Verified Title Deeds",
        "Direct Seller Pricing",
        "Live GPS Locations",
      ],
    ),
    OnboardingSlideItem(
      category: "ZERO MIDDLEMEN",
      title: "Chat Directly with\nProperty Owners",
      subtitle:
          "Skip the broker commissions. Connect straight with verified property owners and certified realtors on WhatsApp or direct phone call.",
      mainIcon: Icons.chat_bubble_outline_rounded,
      badgeLeftIcon: Icons.chat_rounded,
      badgeLeftColor: Color(0xFF25D366),
      badgeLeftText: "Direct WhatsApp",
      badgeRightIcon: Icons.phone_in_talk_rounded,
      badgeRightColor: Color(0xFF0284C7),
      badgeRightText: "Direct Phone Call",
      trustPills: [
        "0% Broker Commission",
        "Instant WhatsApp Deals",
        "Verified Phone Numbers",
      ],
    ),
    OnboardingSlideItem(
      category: "POST FREE AD",
      title: "List Your Property &\nSell 3x Faster",
      subtitle:
          "Post your house, plot, or commercial space in under 2 minutes and reach over 45,000 active buyers and investors nationwide.",
      mainIcon: Icons.rocket_launch_rounded,
      badgeLeftIcon: Icons.bolt_rounded,
      badgeLeftColor: Color(0xFFD97706),
      badgeLeftText: "Free in 2 Mins",
      badgeRightIcon: Icons.groups_rounded,
      badgeRightColor: Color(0xFF059669),
      badgeRightText: "45,000+ Buyers",
      trustPills: [
        "100% Free Listing",
        "Instant Buyer Leads",
        "Nationwide Reach",
      ],
    ),
  ];

  Future<void> _completeOnboarding({String destination = 'home'}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Widget target;
    if (destination == 'register') {
      target = const RegisterScreen();
    } else if (destination == 'login') {
      target = const LoginScreen();
    } else {
      target = BottomNavBarScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == _slides.length - 1) {
      _completeOnboarding(destination: 'register');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Clean Brand Logo & Skip Button (No Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/nlogo.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        "Skip",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Carousel: Pure Fluid Composition (ZERO CARDS)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final item = _slides[index];
                  return _buildSlideContent(item, size);
                },
              ),
            ),

            // Bottom Navigation Area (Zero Cards)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => _buildIndicator(i),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // High-Converting Full-Width Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage ? "Get Started" : "Continue",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Quick Login Option on Last Slide
                  if (isLastPage) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _completeOnboarding(destination: 'login'),
                      child: Text(
                        "Already have an account? Sign In",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF059669),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContent(OnboardingSlideItem item, Size size) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),

            // 1. Organic Visual Halo & Floating Badges (NO CARDS, PURE CANVAS)
            SizedBox(
              height: size.height * 0.32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Soft Mint Halo
                  Container(
                    width: 170,
                    height: 170,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFECFDF5),
                          Color(0xFFF0FDF4),
                        ],
                      ),
                    ),
                  ),

                  // Center Floating Emblem
                  Container(
                    width: 106,
                    height: 106,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        item.mainIcon,
                        size: 50,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),

                  // Floating Left Pill (Freely Floating on Canvas)
                  Positioned(
                    top: 24,
                    left: 0,
                    child: _buildFloatingBadge(
                      item.badgeLeftIcon,
                      item.badgeLeftColor,
                      item.badgeLeftText,
                    ),
                  ),

                  // Floating Right Pill (Freely Floating on Canvas)
                  Positioned(
                    bottom: 24,
                    right: 0,
                    child: _buildFloatingBadge(
                      item.badgeRightIcon,
                      item.badgeRightColor,
                      item.badgeRightText,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.025),

            // 2. Category Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                item.category,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: const Color(0xFF059669),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Bold Fluid Headline
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: -0.4,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 12),

            // 4. Fluid Subtitle Description
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                height: 1.55,
                color: const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 20),

            // 5. Clean Trust Pills (Directly on canvas, no boxes)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: item.trustPills.map((pill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pill,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 6,
      width: isActive ? 26 : 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingSlideItem {
  final String category;
  final String title;
  final String subtitle;
  final IconData mainIcon;
  final IconData badgeLeftIcon;
  final Color badgeLeftColor;
  final String badgeLeftText;
  final IconData badgeRightIcon;
  final Color badgeRightColor;
  final String badgeRightText;
  final List<String> trustPills;

  OnboardingSlideItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.mainIcon,
    required this.badgeLeftIcon,
    required this.badgeLeftColor,
    required this.badgeLeftText,
    required this.badgeRightIcon,
    required this.badgeRightColor,
    required this.badgeRightText,
    required this.trustPills,
  });
}
