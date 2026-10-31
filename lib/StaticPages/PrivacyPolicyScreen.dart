import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/ContactUs.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color primaryGreen = Color(0xFF108224);

  final List<Map<String, dynamic>> _sections = const [
    {
      'num': '1',
      'title': 'Information We Collect',
      'icon': Icons.badge_outlined,
      'content':
          'We may collect personal information that you voluntarily provide, including but not limited to:',
      'bulletPoints': [
        'Full Name',
        'Email Address',
        'Phone Number & WhatsApp Contact',
        'Property Preferences (Location, Budget, Area Size)',
        'Geographical Location Information',
        'Any details submitted through inquiries and contact forms',
      ],
    },
    {
      'num': '2',
      'title': 'How We Use Your Information',
      'icon': Icons.tune_rounded,
      'content': 'The information collected is used strictly for the following operational purposes:',
      'bulletPoints': [
        'Providing verified property buying, renting, and selling services.',
        'Connecting buyers directly with vetted contractors and joint venture partners.',
        'Responding promptly to customer inquiries and technical support tickets.',
        'Enhancing portal functionality, analytics, and personalized user experience.',
        'Delivering important notifications, transaction alerts, and promotional updates.',
        'Maintaining robust security protocols and actively preventing fraudulent activities.',
      ],
    },
    {
      'num': '3',
      'title': 'Cookies and Tracking Technologies',
      'icon': Icons.cookie_outlined,
      'content':
          'Our platform utilizes secure cookies, local device preferences, and analytical tokens to enhance performance, remember your sessions, and optimize search filters.\n\nYou may choose to restrict or disable cookies through your mobile or browser device settings, though certain dynamic features may have limited accessibility.',
    },
    {
      'num': '4',
      'title': 'Information Sharing & Zero Trade',
      'icon': Icons.shield_outlined,
      'content':
          'Dhartti does NOT sell, rent, commercialize, or trade your personal data to any third-party advertisers.\n\nInformation is only disclosed to verified service providers (e.g., payment gateways, SMS OTP providers) or law enforcement authorities solely when required by Pakistani judicial laws and regulations.',
    },
    {
      'num': '5',
      'title': 'Data Security & Storage',
      'icon': Icons.lock_outline_rounded,
      'content':
          'We implement state-of-the-art technical, physical, and administrative measures—including encrypted HTTPS protocols, hashed passwords, and isolated cloud servers—to shield your information from unauthorized access, alteration, or disclosure.\n\nWhile no digital architecture is completely impenetrable, Dhartti adheres strictly to international cybersecurity standards.',
    },
    {
      'num': '6',
      'title': 'Third-Party Links & Integrations',
      'icon': Icons.link_rounded,
      'content':
          'Our mobile application and website may contain hyperlinks to third-party services, including map navigation providers, banking portals, and regulatory schemes. Dhartti is not responsible for the privacy policies or content of external sites.',
    },
    {
      'num': '7',
      'title': 'User Rights & Data Control',
      'icon': Icons.verified_user_outlined,
      'content': 'As a valued Dhartti member, you retain complete authority over your personal information:',
      'bulletPoints': [
        'Right to Access: Request a digital copy of all personal records we hold.',
        'Right to Rectification: Correct inaccurate or outdated account details.',
        'Right to Deletion: Request permanent deletion of your profile and listings.',
        'Right to Withdraw Consent: Opt-out of non-essential promotional messages anytime.',
        'Right to Object: Contest specific automated processing activities.',
      ],
    },
    {
      'num': '8',
      'title': 'Retention of Information',
      'icon': Icons.history_rounded,
      'content':
          'We retain personal records only for as long as necessary to fulfill the primary purposes documented in this policy, support active transactions, or satisfy statutory legal and tax record-keeping requirements.',
    },
    {
      'num': '9',
      'title': 'Children\'s Privacy',
      'icon': Icons.family_restroom_rounded,
      'content':
          'Dhartti\'s real estate portal and bidding services are designed strictly for adults of legal contracting age. We do not knowingly solicit or collect personal identifiable information from children under 13.',
    },
    {
      'num': '10',
      'title': 'Changes to This Privacy Policy',
      'icon': Icons.update_rounded,
      'content':
          'Dhartti reserves the right to amend or update this Privacy Policy periodically. Any modifications take immediate effect upon being published in our app and web views, with notification provided for significant changes.',
    },
    {
      'num': '11',
      'title': 'Contact Our Data Protection Officer',
      'icon': Icons.support_agent_rounded,
      'content':
          'If you have questions, grievances, or requests regarding this Privacy Policy or your personal data handling, our legal advisory team is at your service:',
      'bulletPoints': [
        'Email: info@dhartti.com',
        'Direct Phone: +61 430 616 980',
        'Head Office: Gohar Rabi Centre, Tariq Rd, Block 3 P.E.C.H.S., Karachi',
      ],
    },
  ];

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
          'Privacy Policy',
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
            const SizedBox(height: 18),
            _buildTrustHighlights(),
            const SizedBox(height: 20),
            _buildPolicySections(context),
            const SizedBox(height: 28),
            _buildContactCta(context),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Home', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              Text(' / Legal / ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
              Text('Privacy Policy', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Security & Trust',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Privacy Policy',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your privacy is important to us. This Privacy Policy explains how Dhartti collects, uses, and protects your information when you use our website and mobile applications.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustHighlights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTrustItem(
              icon: Icons.money_off_csred_rounded,
              title: 'No Data Trade',
              desc: 'Never sold to advertisers',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTrustItem(
              icon: Icons.enhanced_encryption_rounded,
              title: 'Encrypted',
              desc: 'Bank-grade SSL security',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTrustItem(
              icon: Icons.manage_accounts_rounded,
              title: 'Full Control',
              desc: 'Delete or edit records',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _sections.map((sec) {
          final List<String>? bullets = sec['bulletPoints'] as List<String>?;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(sec['icon'] as IconData, color: primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${sec['num']}. ${sec['title']}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sec['content'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    height: 1.55,
                  ),
                ),
                if (bullets != null && bullets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...bullets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6, right: 8),
                              child: Icon(Icons.circle, size: 6, color: primaryGreen),
                            ),
                            Expanded(
                              child: Text(
                                b,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactCta(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              color: primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Privacy Inquiries',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Need Further Clarity on Your Data?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Contact our legal grievance cell or submit a direct subject access request through our official channels.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
              icon: Text(
                'Open Contact Page',
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
