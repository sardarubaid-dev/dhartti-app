import 'package:dhartti/service/seller_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerInquiriesScreen extends StatefulWidget {
  const SellerInquiriesScreen({Key? key}) : super(key: key);

  @override
  State<SellerInquiriesScreen> createState() => _SellerInquiriesScreenState();
}

class _SellerInquiriesScreenState extends State<SellerInquiriesScreen> {
  final SellerService _sellerService = SellerService();
  bool _isLoading = true;
  List<dynamic> _inquiries = [];

  static const Color dharttiGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    setState(() => _isLoading = true);
    final list = await _sellerService.fetchInquiries();
    if (mounted) {
      setState(() {
        _inquiries = list;
        _isLoading = false;
      });
    }
  }

  void _callPhone(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not provided by buyer')),
      );
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer for $phone')),
        );
      }
    }
  }

  void _openWhatsApp(String phone, String propertyTitle) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not provided by buyer')),
      );
      return;
    }
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '92${cleanPhone.substring(1)}';
    }
    final text = Uri.encodeComponent(
      'Salam, I am contacting you from Dhartti regarding your inquiry on "$propertyTitle".',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          'Buyer Inquiries & Leads',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: dharttiGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInquiries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: dharttiGreen),
            )
          : RefreshIndicator(
              color: dharttiGreen,
              onRefresh: _loadInquiries,
              child: _inquiries.isEmpty ? _buildEmptyState() : _buildInquiriesList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dharttiGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: dharttiGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Inquiries Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When buyers or agents inquire about your listed properties, their contact details and messages will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _inquiries.length,
      itemBuilder: (context, index) {
        final item = _inquiries[index];
        final propertyTitle = item['property_title']?.toString() ?? 'Property';
        final propertyImage = item['property_image']?.toString();
        final senderName = item['sender_name']?.toString() ?? 'Buyer';
        final senderPhone = item['sender_phone']?.toString() ?? '';
        final senderEmail = item['sender_email']?.toString() ?? '';
        final message = item['message']?.toString() ?? '';
        final date = item['created_at']?.toString() ?? '';
        final inquiryType = item['inquiry_type']?.toString() ?? 'Direct Inquiry';
        final propertyCity = item['property_city']?.toString() ?? '';
        final propertyPrice = item['property_price']?.toString() ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: Colors.grey.shade200,
                        child: propertyImage != null && propertyImage.isNotEmpty
                            ? Image.network(
                                propertyImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.home_work_outlined, color: Colors.grey),
                              )
                            : const Icon(Icons.home_work_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          if (propertyPrice.isNotEmpty || propertyCity.isNotEmpty)
                            Text(
                              [propertyPrice, propertyCity].where((e) => e.isNotEmpty).join(' • '),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: dharttiGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  inquiryType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                date,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 1),

                // Buyer Details & Message
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: dharttiGreen.withOpacity(0.12),
                      child: const Icon(Icons.person, size: 16, color: dharttiGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          if (senderEmail.isNotEmpty)
                            Text(
                              senderEmail,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (senderPhone.isNotEmpty)
                      Text(
                        senderPhone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Message Bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade800,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: Call & WhatsApp
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callPhone(senderPhone),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: dharttiGreen),
                        label: Text(
                          'Call',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: dharttiGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: dharttiGreen),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(senderPhone, propertyTitle),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'WhatsApp',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
