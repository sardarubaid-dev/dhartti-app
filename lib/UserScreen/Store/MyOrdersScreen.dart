import 'package:dhartti/Model/store_model.dart';
import 'package:dhartti/service/store_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final StoreService _storeService = StoreService();
  bool _isLoading = true;
  List<StoreOrderModel> _orders = [];
  int? _userId;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAFC);
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawUserId = prefs.get('userId');
      final safeUserId = rawUserId is int
          ? rawUserId
          : (rawUserId is String ? int.tryParse(rawUserId) : null);
      _userId = safeUserId;

      final phone = prefs.getString('userPhone') ?? prefs.getString('phone');

      final fetched = await _storeService.fetchUserOrders(
        userId: _userId,
        phone: phone,
      );

      if (mounted) {
        setState(() {
          _orders = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("MyOrdersScreen _loadOrders error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Store Orders",
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: dharttiGreen, size: 22),
            tooltip: 'Refresh Orders',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
          : RefreshIndicator(
              color: dharttiGreen,
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(_orders[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildOrderCard(StoreOrderModel order) {
    Color statusColor;
    Color statusBg;
    final statusLower = order.status.toLowerCase();

    if (statusLower == 'completed' || statusLower == 'delivered') {
      statusColor = dharttiGreen;
      statusBg = const Color(0xFFE8F7EC);
    } else if (statusLower == 'processing') {
      statusColor = Colors.blue.shade700;
      statusBg = const Color(0xFFEFF6FF);
    } else if (statusLower == 'cancelled') {
      statusColor = Colors.red.shade700;
      statusBg = const Color(0xFFFEF2F2);
    } else {
      // Pending
      statusColor = Colors.orange.shade800;
      statusBg = const Color(0xFFFFFBEB);
    }

    String formattedDate = '';
    if (order.createdAt != null && order.createdAt!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(order.createdAt!);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
      } catch (_) {
        formattedDate = order.createdAt!.length > 10
            ? order.createdAt!.substring(0, 10)
            : order.createdAt!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: dharttiGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long, color: dharttiGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Order #${order.id}",
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 35),
              child: Text(
                formattedDate,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Items List
          if (order.items.isNotEmpty)
            Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${item.quantity}x",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "PKR ${_currencyFormat.format(item.subtotal)}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text(
              "Order items information unavailable",
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade500),
            ),

          const SizedBox(height: 6),

          // Shipping Address
          if (order.shippingAddress.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: dharttiGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.shippingAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          const Divider(height: 1),
          const SizedBox(height: 10),

          // Total & Payment Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Total Amount",
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.paymentStatus.toLowerCase() == 'paid'
                          ? const Color(0xFFE8F7EC)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.paymentStatus.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: order.paymentStatus.toLowerCase() == 'paid'
                            ? dharttiGreen
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "PKR ${_currencyFormat.format(order.totalAmount)}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dharttiGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: dharttiGreen,
                size: 58,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No Orders Yet",
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You have not placed any orders from Dhartti Construction Store yet. Browse our verified products and order directly.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_outlined, size: 18, color: Colors.white),
              label: Text(
                "Browse Store",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
