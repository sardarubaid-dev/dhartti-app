import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/UserScreen/PropertyScreen/propertyListScreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:dhartti/UserScreen/AllProject.dart';
import 'package:dhartti/CostCalculatorScreen.dart';
import 'package:dhartti/ContactUs.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const Color primaryGreen = Color(0xFF108224);

  final List<Map<String, dynamic>> _coreServices = [
    {
      'title': 'Buy A New Home',
      'subtitle': 'Verified Sale Listings & Ownership Guarantee',
      'desc':
          'Unlock the doors to your dream residence with verified society NOCs, accurate map coordinates, and complete legal ownership vetting.',
      'icon': Icons.home_outlined,
      'color': Color(0xFF1E3A8A),
      'action': 'Explore Homes',
      'type': 'buy',
    },
    {
      'title': 'Rent A Home',
      'subtitle': 'Curated Residential & Commercial Portfolios',
      'desc':
          'Select from a curated variety of rentals tailored to your lifestyle, verified directly with owners with zero fake duplicate ads.',
      'icon': Icons.key_outlined,
      'color': primaryGreen,
      'action': 'Find Rentals',
      'type': 'rent',
    },
    {
      'title': 'Sell Your Property',
      'subtitle': 'High-Exposure Marketing & Direct Leads',
      'desc':
          'Maximize your property’s value with targeted digital promotion, verified buyer inquiries, and transparent price negotiations.',
      'icon': Icons.sell_outlined,
      'color': Color(0xFF7C3AED),
      'action': 'List Property',
      'type': 'sell',
    },
    {
      'title': 'Joint Ventures & Projects',
      'subtitle': 'Developer Partnerships & Transparent Bidding',
      'desc':
          'Connect land owners with vetted builders and contractors through our digital milestone-based joint venture bidding ecosystem.',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF0D9488),
      'action': 'Browse Projects',
      'type': 'project',
    },
    {
      'title': 'Construction Cost Tool',
      'subtitle': 'Localized Material & Labor Calculator',
      'desc':
          'Calculate accurate grey structure and turnkey finishing costs in Marla/Kanal according to current market rates in Pakistan.',
      'icon': Icons.calculate_outlined,
      'color': Color(0xFFD97706),
      'action': 'Calculate Cost',
      'type': 'calc',
    },
    {
      'title': 'Legal Due Diligence',
      'subtitle': 'Supreme Court Advocate Title Audits',
      'desc':
          'Avoid fraud with professional deed verification, society approval checks, and dispute-free sales agreement drafting.',
      'icon': Icons.gavel_rounded,
      'color': Color(0xFFDC2626),
      'action': 'Consult Legal',
      'type': 'legal',
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Why should I use Dhartti services?',
      'a':
          'We eliminate fraudulent listings, unverified agents, and hidden charges. Every property title is legally scrutinized and direct owner chat ensures 100% transparency.',
    },
    {
      'q': 'How do I get started with your services?',
      'a':
          'Simply sign up with your email or phone, browse our verified catalog or list your own property in minutes using our guided form.',
    },
    {
      'q': 'How secure are property transactions on Dhartti?',
      'a':
          'Our legal advisory team walks alongside you from agreement drafting to registrar transfer, safeguarding your earnest money and contract terms.',
    },
    {
      'q': 'Is customer support available 24/7?',
      'a':
          'Yes, our team is reachable round the clock via in-app live chat, direct helpline at +61 430 616 980, and email at info@dhartti.com.',
    },
    {
      'q': 'Can I update or manage my active listings?',
      'a':
          'Yes, through your dedicated Seller Dashboard you can edit prices, add new photos, toggle installment terms, and track real-time view counts.',
    },
  ];

  void _handleServiceTap(String type) {
    switch (type) {
      case 'buy':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyListScreen(initialPurpose: 'sell')));
        break;
      case 'rent':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyListScreen(initialPurpose: 'rent')));
        break;
      case 'sell':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen()));
        break;
      case 'project':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreens()));
        break;
      case 'calc':
        Navigator.push(context, MaterialPageRoute(builder: (_) => CostCalculatorForm()));
        break;
      case 'legal':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Our Services',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER
            _buildHeroHeader(),

            const SizedBox(height: 20),

            // 2. FOUR PILLARS OF EXCELLENCE
            _buildPillarsRow(),

            const SizedBox(height: 24),

            // 3. CORE SERVICES GRID / CARDS
            _buildServicesList(),

            const SizedBox(height: 24),

            // 4. FAQ SECTION
            _buildFaqSection(),

            const SizedBox(height: 24),

            // 5. CTA SECTION
            _buildCtaSection(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        gradient: LinearGradient(
          colors: [primaryGreen, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Premium Solutions',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Exquisite Real Estate Solutions Tailored for You',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Experience a new standard of real estate excellence. Whether you are buying your first home or expanding your portfolio, our dedicated team ensures every transaction is handled with precision and care.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsRow() {
    final pillars = [
      {'title': 'Premium Quality', 'icon': Icons.star_outline_rounded},
      {'title': 'Trusted Advice', 'icon': Icons.verified_user_outlined},
      {'title': 'Seamless Process', 'icon': Icons.swap_horiz_rounded},
      {'title': 'Local Expertise', 'icon': Icons.location_on_outlined},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: pillars.map((p) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(p['icon'] as IconData, size: 20, color: primaryGreen),
                  const SizedBox(height: 6),
                  Text(
                    p['title'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServicesList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Capabilities',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
          ),
          const SizedBox(height: 4),
          Text(
            'What We Offer to Our Community',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),
          ..._coreServices.map((s) {
            final color = s['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(s['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              s['subtitle'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s['desc'] as String,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleServiceTap(s['type'] as String),
                      icon: Text(
                        s['action'] as String,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                      label: Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color.withOpacity(0.4), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FAQs',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
          ),
          const SizedBox(height: 4),
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          ..._faqs.map((f) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    f['q']!,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                  iconColor: primaryGreen,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Text(
                      f['a']!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.45),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCtaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'List your Properties on Dhartti',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Experience verified leads, digital bidding, and transparent client communication.',
            style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Become A Partner',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
