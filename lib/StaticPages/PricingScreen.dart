import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/UserScreen/PropertyScreen/propertyListScreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:dhartti/ContactUs.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  static const Color primaryGreen = Color(0xFF108224);
  bool _isAnnual = false;

  final List<Map<String, dynamic>> _pricingPlans = [
    {
      'title': 'Intro',
      'monthlyPrice': 20,
      'annualPrice': 16,
      'desc': 'Join us every month for a very reasonable price',
      'isPopular': false,
      'features': [
        {'text': 'Transportation for you', 'enabled': true},
        {'text': 'A hotel or homestay', 'enabled': true},
        {'text': 'Free meals and drinks', 'enabled': true},
        {'text': '24/7 Support', 'enabled': false},
        {'text': 'Unlimited users', 'enabled': false},
      ],
      'color': const Color(0xFF64748B),
    },
    {
      'title': 'Base',
      'monthlyPrice': 99,
      'annualPrice': 79,
      'desc': 'Join us every month for a very reasonable price',
      'isPopular': false,
      'features': [
        {'text': 'Transportation for you', 'enabled': true},
        {'text': 'A hotel or homestay', 'enabled': true},
        {'text': 'Free meals and drinks', 'enabled': true},
        {'text': '24/7 Support', 'enabled': false},
        {'text': 'Unlimited users', 'enabled': false},
      ],
      'color': const Color(0xFF2563EB),
    },
    {
      'title': 'Pro',
      'monthlyPrice': 150,
      'annualPrice': 120,
      'desc': 'Join us every month for a very reasonable price',
      'isPopular': true,
      'badge': 'MOST POPULAR',
      'features': [
        {'text': 'Transportation for you', 'enabled': true},
        {'text': 'A hotel or homestay', 'enabled': true},
        {'text': 'Free meals and drinks', 'enabled': true},
        {'text': '24/7 Support', 'enabled': true},
        {'text': 'Unlimited users', 'enabled': false},
      ],
      'color': primaryGreen,
    },
    {
      'title': 'Enterprise',
      'monthlyPrice': 200,
      'annualPrice': 160,
      'desc': 'Join us every month for a very reasonable price',
      'isPopular': false,
      'badge': 'BEST FOR TEAMS',
      'features': [
        {'text': 'Transportation for you', 'enabled': true},
        {'text': 'A hotel or homestay', 'enabled': true},
        {'text': 'Free meals and drinks', 'enabled': true},
        {'text': '24/7 Support', 'enabled': true},
        {'text': 'Unlimited users', 'enabled': true},
      ],
      'color': const Color(0xFF7C3AED),
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Why should I use your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'q': 'How do I get started with your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'q': 'How secure are your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'q': 'Is there customer support available?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'q': 'How can I update my account information?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
  ];

  void _onSelectPlan(String planTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: primaryGreen, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Subscribe to $planTitle Plan',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Enjoy premium benefits, verified lead priority, and zero hidden charges.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PropertyListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'View All Properties',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGreen, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Contact Sales Support',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: primaryGreen),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Pricing',
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 20),
            _buildBillingToggle(),
            const SizedBox(height: 20),
            _buildPricingCards(),
            const SizedBox(height: 28),
            _buildFaqSection(),
            const SizedBox(height: 28),
            _buildHostingBanner(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        image: DecorationImage(
          image: AssetImage('assets/dhartti_logo.png'),
          alignment: Alignment.centerRight,
          opacity: 0.05,
          fit: BoxFit.contain,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Home', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              Text(' / Pages / ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
              Text('Pricing', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGreen.withOpacity(0.4)),
            ),
            child: Text(
              'Pricing Plans',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our Subscription',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the right plan tailored to your property investment, sales, and management needs.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: !_isAnnual ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Monthly',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: !_isAnnual ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAnnual ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(
                      'Annual',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _isAnnual ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isAnnual ? Colors.white : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'SAVE 20%',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isAnnual ? primaryGreen : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _pricingPlans.map((plan) => _buildPlanCard(plan)).toList(),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final bool isPopular = plan['isPopular'] as bool;
    final int price = _isAnnual ? (plan['annualPrice'] as int) : (plan['monthlyPrice'] as int);
    final String title = plan['title'] as String;
    final String desc = plan['desc'] as String;
    final List<Map<String, dynamic>> features = plan['features'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? primaryGreen : Colors.grey.shade200,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? primaryGreen.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan['badge'] != null) const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$$price',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isAnnual ? '/month, billed annually' : '/month',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                ...features.map((f) {
                  final bool enabled = f['enabled'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: enabled ? primaryGreen.withOpacity(0.12) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            enabled ? Icons.check_rounded : Icons.close_rounded,
                            size: 13,
                            color: enabled ? primaryGreen : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f['text'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: enabled ? const Color(0xFF334155) : Colors.grey.shade400,
                              fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
                              decoration: enabled ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onSelectPlan(title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? primaryGreen : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: isPopular ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View All Properties',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (plan['badge'] != null)
            Positioned(
              top: -10,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPopular ? primaryGreen : const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isPopular ? primaryGreen : const Color(0xFF7C3AED)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  plan['badge'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
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
          Center(
            child: Column(
              children: [
                Text(
                  'Faqs',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ..._faqs.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, String> f = entry.value;
            final bool isInitialOpen = index == 1; // Accordion #2 is active in blade
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
                  initiallyExpanded: isInitialOpen,
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

  Widget _buildHostingBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Become Partners',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'List your Properties on Dhartti, join Us Now!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join our verified network of sellers, contractors, and agents to accelerate closures with trusted transparency.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
                );
              },
              icon: Text(
                'Become A Hosting',
                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
