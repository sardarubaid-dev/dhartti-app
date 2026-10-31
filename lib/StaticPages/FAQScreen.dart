import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/ContactUs.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  static const Color primaryGreen = Color(0xFF108224);
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allFaqs = [
    // Overview (Web Section 1)
    {
      'category': 'Overview',
      'q': 'Why should I use your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Overview',
      'q': 'How do I get started with your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Overview',
      'q': 'How secure are your services?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Overview',
      'q': 'Is there customer support available?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Overview',
      'q': 'How can I update my account information?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },

    // Costs and Payments (Web Section 2)
    {
      'category': 'Costs and Payments',
      'q': 'How do you calculate fees?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Costs and Payments',
      'q': 'How do I pay Message?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Costs and Payments',
      'q': 'Are there opportunities for discounts or promotions?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Costs and Payments',
      'q': 'Are there any hidden fees not displayed in the pricing table?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Costs and Payments',
      'q': 'What is the refund procedure?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Costs and Payments',
      'q': 'Is there financial or accounting support?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },

    // Safety and Security (Web Section 3)
    {
      'category': 'Safety and Security',
      'q': 'What languages does your service support?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Safety and Security',
      'q': 'How do I integrate your service into my system?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Safety and Security',
      'q': 'What are the safety features of your system?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Safety and Security',
      'q': 'How can I request new features?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Safety and Security',
      'q': 'Is my data protected?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
    {
      'category': 'Safety and Security',
      'q': 'How do I report a technical issue?',
      'a':
          'Once your account is set up and you\'ve familiarized yourself with the platform, you are ready to start using our services. Whether it\'s accessing specific features, making transactions, or utilizing our tools, you\'ll find everything you need at your fingertips.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          (faq['q'] as String).toLowerCase().contains(query) ||
          (faq['a'] as String).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Overview', 'Costs and Payments', 'Safety and Security'];

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
          'FAQs',
          style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildCategoryChips(categories),
            const SizedBox(height: 16),
            _buildFaqList(),
            const SizedBox(height: 28),
            _buildContactSupportBanner(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Home', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              Text(' / Pages / ', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
              Text('FAQs', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
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
              'Help Center',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Frequently Asked Questions',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find answers to all your common inquiries regarding real estate, bidding, and portal security.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.poppins(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search questions, payments, security...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: Colors.white,
              selectedColor: primaryGreen,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqList() {
    final faqs = _filteredFaqs;

    if (faqs.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No questions found',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search terms or selecting another category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: faqs.map((f) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  f['q'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    f['category'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: primaryGreen,
                    ),
                  ),
                ),
                iconColor: primaryGreen,
                collapsedIconColor: Colors.grey.shade500,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Text(
                    f['a'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      height: 1.5,
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

  Widget _buildContactSupportBanner() {
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
              'Still Have Questions?',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4ADE80)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We Are Here To Help You 24/7',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cannot find the answer you\'re looking for? Reach out to our dedicated support and legal advisory team anytime.',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, height: 1.45),
          ),
          const SizedBox(height: 16),
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
                'Contact Customer Support',
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
