import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/service/ContactService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  static const Color primaryGreen = Color(0xFF108224);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final ContactService _contactService = ContactService();
  bool _isSubmitting = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Why Dhartti?',
      'answer':
          'We prioritize transparency, legal security, and user experience above all else. Our platform is engineered to be the fastest way to discover 100% verified listings without fake pictures or broker clutter.',
    },
    {
      'question': 'What is the Listing Process?',
      'answer':
          'Listing is seamless: sign up, enter your property specifications with images, and our verification team reviews society NOC and titles within 24 hours before making it live to thousands of buyers.',
    },
    {
      'question': 'How secure is my data?',
      'answer':
          'We employ end-to-end encryption for all inquiries, direct seller chats, and lead data. We never share your personal contact details with unauthorized third parties or telemarketers.',
    },
    {
      'question': 'Is Customer Support available 24/7?',
      'answer':
          'Yes! Our dedicated customer support desk and legal advisors are available around the clock via in-app chat, email at info@dhartti.com, and direct phone lines.',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Inquiry from Dhartti App');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone_number': _phoneController.text.trim(),
        'Subject': _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : 'General Inquiry',
        'Message': _messageController.text.trim(),
      };

      await _contactService.createContact(payload);

      if (!mounted) return;
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _subjectController.clear();
      _messageController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: primaryGreen, size: 26),
              const SizedBox(width: 8),
              Text(
                'Message Sent',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Thank you for reaching out! Our team has received your inquiry and will respond within 24 business hours.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Contact Us',
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
            // 1. HERO BANNER
            _buildHeroHeader(),

            const SizedBox(height: 18),

            // 2. CONTACT CHANNELS (PHONE, EMAIL, LOCATION)
            _buildContactCards(),

            const SizedBox(height: 24),

            // 3. SEND US A MESSAGE FORM
            _buildInquiryForm(),

            const SizedBox(height: 24),

            // 4. COMMON QUESTIONS (FAQ ACCORDION)
            _buildFaqSection(),

            const SizedBox(height: 24),

            // 5. READY TO LIST CTA BANNER
            _buildCtaSection(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HERO HEADER
  // ==========================================
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
              'Get In Touch',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect With Us',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We’d love to hear from you. Have inquiries about listings, partnership opportunities, or technical help? Reach out to our dedicated team.',
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

  // ==========================================
  // CONTACT INFO CARDS
  // ==========================================
  Widget _buildContactCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Our Location',
            subtitle: 'Gohar Rabi Centre, Tariq Rd, Block 3 P.E.C.H.S., Karachi, Pakistan',
            badge: 'Headquarters',
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.phone_in_talk_outlined,
            title: 'Direct Phone',
            subtitle: '+61 430 616 980 / 021-34567890',
            badge: 'Mon-Sat 9AM-7PM',
            color: primaryGreen,
            onTap: () => _makeCall('+61430616980'),
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.alternate_email_rounded,
            title: 'Email Address',
            subtitle: 'info@dhartti.com / support@dhartti.com',
            badge: '24/7 Response',
            color: Colors.purple.shade700,
            onTap: () => _sendEmail('info@dhartti.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // INQUIRY FORM
  // ==========================================
  Widget _buildInquiryForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Us A Message',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill out the form below and our team will get back to you promptly.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _nameController,
              label: 'Your Name *',
              hint: 'e.g. Muhammad Ali',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            _buildInputField(
              controller: _emailController,
              label: 'Email Address *',
              hint: 'e.g. ali@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter valid email address';
                return null;
              },
            ),
            _buildInputField(
              controller: _phoneController,
              label: 'Phone Number *',
              hint: 'e.g. 03001234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
            ),
            _buildInputField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'e.g. Property Listing Inquiry / Joint Venture',
              icon: Icons.topic_outlined,
            ),
            _buildInputField(
              controller: _messageController,
              label: 'Message *',
              hint: 'How can we help you?',
              icon: Icons.message_outlined,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please write your message' : null,
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send Message',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.poppins(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12.5),
              prefixIcon: Icon(icon, color: primaryGreen, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryGreen, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FAQ SECTION
  // ==========================================
  Widget _buildFaqSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Questions',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
          ),
          const SizedBox(height: 4),
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          ..._faqs.map((faq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                  iconColor: primaryGreen,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: [
                    Text(
                      faq['answer']!,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
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

  // ==========================================
  // CTA SECTION
  // ==========================================
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
            'Ready to list your property?',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Join thousands of verified agents, developers, and sellers on Pakistan’s most modern real estate network.',
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
                'Get Started Today',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
