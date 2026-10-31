import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dhartti/service/seller_service.dart';

class MyBidsTrackingScreen extends StatefulWidget {
  const MyBidsTrackingScreen({Key? key}) : super(key: key);

  @override
  _MyBidsTrackingScreenState createState() => _MyBidsTrackingScreenState();
}

class _MyBidsTrackingScreenState extends State<MyBidsTrackingScreen>
    with SingleTickerProviderStateMixin {
  final SellerService _sellerService = SellerService();
  late TabController _tabController;

  bool _isLoading = true;
  List<dynamic> _projectBids = [];
  List<dynamic> _ventureBids = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBids();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    setState(() => _isLoading = true);
    final data = await _sellerService.fetchMyBids();
    if (mounted) {
      setState(() {
        _projectBids = data['project_bids'] ?? [];
        _ventureBids = data['venture_bids'] ?? [];
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Bids (Tracking)',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF108224),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBids,
            tooltip: 'Refresh Bids',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.apartment_rounded, size: 20),
              text: 'Projects (${_projectBids.length})',
            ),
            Tab(
              icon: const Icon(Icons.group_work_rounded, size: 20),
              text: 'Joint Ventures (${_ventureBids.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF108224)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBidsList(_projectBids, isProject: true),
                _buildBidsList(_ventureBids, isProject: false),
              ],
            ),
    );
  }

  Widget _buildBidsList(List<dynamic> bids, {required bool isProject}) {
    if (bids.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBids,
        color: const Color(0xFF108224),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isProject ? Icons.apartment_outlined : Icons.group_work_outlined,
                      size: 48,
                      color: const Color(0xFF108224),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isProject ? 'No project bids placed yet' : 'No joint venture bids placed yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you bid on other projects or ventures,\ntheir tracking status will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBids,
      color: const Color(0xFF108224),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final bid = bids[index];
          return _buildBidCard(bid, isProject: isProject);
        },
      ),
    );
  }

  Widget _buildBidCard(dynamic bid, {required bool isProject}) {
    final status = (bid['status'] ?? 'Pending').toString();
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    final title = isProject
        ? (bid['project']?['title'] ?? 'Project #${bid['project_id'] ?? ''}')
        : (bid['venture']?['title'] ?? 'Venture #${bid['venture_id'] ?? ''}');

    final priceOrAmount = isProject
        ? (bid['bid_price'] != null ? 'PKR ${bid['bid_price']}' : 'Not specified')
        : (bid['amount'] != null ? 'PKR ${bid['amount']}' : 'Not specified');

    final message = isProject ? (bid['bid_description'] ?? '') : (bid['message'] ?? '');
    final ownerReply = bid['owner_reply'] as String?;
    final date = _formatDate(bid['created_at']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Bid Amount Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF108224).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    size: 16,
                    color: Color(0xFF108224),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Offered Bid: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  priceOrAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF108224),
                  ),
                ),
              ],
            ),

            // My Bid Proposal / Message
            if (message.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Proposal / Message:',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Owner Response / Feedback if available
            if (ownerReply != null && ownerReply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: status == 'Accepted' ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: status == 'Accepted' ? Colors.green.shade200 : Colors.amber.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: status == 'Accepted' ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Owner Reply:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: status == 'Accepted' ? Colors.green.shade800 : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerReply,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
