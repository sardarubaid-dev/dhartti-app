import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/IntroScreens/team_photos.dart';
import 'package:dhartti/ContactUs.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const Color primaryGreen = Color(0xFF059669);

  final List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'MR Shehbaz Mirani',
      'role': 'CEO & Founder',
      'image': 'assets/images/shehbaz-mirani.jpeg',
      'base64': '',
      'isCeo': true,
      'signature': 'assets/images/signature.png',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'name': 'Advocate Shahab Sarki',
      'role': 'Sr. Legal Advisor',
      'image': 'assets/images/shahab-sarki.jpeg',
      'base64': TeamPhotos.shahabSarki,
      'isCeo': false,
      'icon': Icons.gavel_rounded,
      'color': const Color(0xFF1E3A8A),
    },
    {
      'name': 'Advocate Ali Abbass Mirani',
      'role': 'Assistant Legal Advisor',
      'image': 'assets/images/ali-abbass-mirani.jpeg',
      'base64': TeamPhotos.aliAbbass,
      'isCeo': false,
      'icon': Icons.balance_rounded,
      'color': const Color(0xFF0D9488),
    },
    {
      'name': 'Sardar Uzair',
      'role': 'Technology Partner / CTO',
      'image': 'assets/images/sardar-uzair.jpeg',
      'base64': TeamPhotos.sardarUzair,
      'isCeo': false,
      'icon': Icons.code_rounded,
      'color': const Color(0xFF7C3AED),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/nlogo.png',
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'About Dhartti',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BRAND WELCOME & CEO SPOTLIGHT
            _buildWelcomeSection(),

            const SizedBox(height: 20),

            // 2. LEADERSHIP TEAM (EXECUTIVE HORIZONTAL CARDS)
            _buildTeamSection(),

            const SizedBox(height: 24),

            // 3. CLEAN CONTACT FOOTER
            _buildFooterContact(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BRAND WELCOME (CLEAN & MINIMAL)
  // ==========================================
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: primaryGreen, size: 13),
                const SizedBox(width: 5),
                Text(
                  'Pakistan’s Trusted Property Network',
                  style: GoogleFonts.poppins(
                    color: primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            'Welcome to Dhartti',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),

          // Intro paragraph
          Text(
            'Where we turn houses into homes and dreams into reality. At Dhartti, we empower every Pakistani to buy, sell, and finance verified real estate safely — backed by senior legal advisors and advanced prop-tech infrastructure.',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEADERSHIP TEAM (EXECUTIVE HORIZONTAL CARDS)
  // ==========================================
  Widget _buildTeamSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Leadership',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Executive & Advisory Team',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ..._teamMembers.map((m) {
            final color = m['color'] as Color;
            final isCeo = m['isCeo'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCeo
                      ? primaryGreen.withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0),
                  width: isCeo ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCeo
                        ? primaryGreen.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT SLAB: Curved Emerald Accent Container with Centered Circular Photo
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCeo
                                ? [const Color(0xFF065F46), const Color(0xFF047857)]
                                : [const Color(0xFF059669), const Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                            topRight: Radius.circular(34),
                            bottomRight: Radius.circular(34),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildTeamImage(
                              assetPath: m['image'] as String,
                              base64Data: m['base64'] as String,
                              size: 59,
                              isCeo: isCeo,
                            ),
                          ),
                        ),
                      ),

                      // CENTER: Name & Role Badge (Clean, No paragraph descriptions!)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      m['name'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: isCeo ? 15 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCeo) ...[
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Color(0xFFD97706),
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.25),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(m['icon'] as IconData,
                                            size: 12, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          m['role'] as String,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (isCeo && m['signature'] != null) ...[
                                const SizedBox(height: 6),
                                Image.asset(
                                  m['signature'] as String,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // RIGHT COLUMN: Verification & Role Icons
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              m['icon'] as IconData,
                              size: 15,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // BULLETPROOF IMAGE RENDERER
  // ==========================================
  Widget _buildTeamImage({
    required String assetPath,
    required String base64Data,
    required double size,
    bool isCeo = false,
  }) {
    if (isCeo && base64Data.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'SM',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        if (base64Data.isNotEmpty) {
          try {
            return Image.memory(
              base64Decode(base64Data),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _buildAvatarFallback(size, isCeo: isCeo),
            );
          } catch (_) {
            return _buildAvatarFallback(size, isCeo: isCeo);
          }
        }
        return _buildAvatarFallback(size, isCeo: isCeo);
      },
    );
  }

  Widget _buildAvatarFallback(double size, {bool isCeo = false}) {
    if (isCeo) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF047857),
        alignment: Alignment.center,
        child: Text(
          'SM',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 26, color: Color(0xFF64748B)),
    );
  }

  // ==========================================
  // CLEAN FOOTER (CONTACT ACTION)
  // ==========================================
  Widget _buildFooterContact() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mail_outline_rounded, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have Questions?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Our legal & advisory team is available 24/7',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ContactPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Contact',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
