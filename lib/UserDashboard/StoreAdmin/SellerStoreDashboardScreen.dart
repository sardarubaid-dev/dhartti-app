import 'package:dhartti/UserDashboard/StoreAdmin/AddEditStoreProductScreen.dart';
import 'package:dhartti/constants.dart';
import 'package:dhartti/service/seller_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SellerStoreDashboardScreen extends StatefulWidget {
  const SellerStoreDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SellerStoreDashboardScreen> createState() => _SellerStoreDashboardScreenState();
}

class _SellerStoreDashboardScreenState extends State<SellerStoreDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SellerService _sellerService = SellerService();

  bool _isLoadingProducts = true;
  bool _isLoadingOrders = true;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];

  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  static const Color dharttiGreen = Color(0xFF108224);

  String _resolveProductImageUrl(dynamic path) {
    if (path == null) return '';
    final str = path.toString().trim();
    if (str.isEmpty || str == 'null') return '';
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return str;
    }
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    var clean = str;
    if (clean.startsWith('/')) clean = clean.substring(1);
    if (!clean.startsWith('uploads/')) {
      clean = 'uploads/products/$clean';
    }
    return '$base/$clean';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final list = await _sellerService.fetchStoreProducts();
    if (mounted) {
      setState(() {
        _products = list;
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    final list = await _sellerService.fetchStoreOrders();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _deleteProduct(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "$name" from your store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _sellerService.deleteStoreProduct(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully'), backgroundColor: dharttiGreen),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete product'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showOrderStatusDialog(int orderId, String currentStatus) {
    final statuses = ['Pending', 'Processing', 'Delivered', 'Cancelled'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Update Order Status (Order #$orderId)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(),
              ...statuses.map((status) {
                final isCurrent = status == currentStatus;
                return ListTile(
                  leading: Icon(
                    isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isCurrent ? dharttiGreen : Colors.grey,
                  ),
                  title: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? dharttiGreen : Colors.black87,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (!isCurrent) {
                      final res = await _sellerService.updateStoreOrderStatus(orderId, status);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Status updated'),
                            backgroundColor: res['success'] == true ? dharttiGreen : Colors.red,
                          ),
                        );
                        if (res['success'] == true) _loadOrders();
                      }
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          'Store Management Panel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: dharttiGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: 'My Products'),
            Tab(icon: Icon(Icons.shopping_bag_outlined, size: 20), text: 'Orders Received'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dharttiGreen,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditStoreProductScreen()),
          );
          if (res == true) _loadProducts();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Products
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
              : RefreshIndicator(
                  color: dharttiGreen,
                  onRefresh: _loadProducts,
                  child: _products.isEmpty ? _buildEmptyProducts() : _buildProductsList(),
                ),

          // Tab 2: Orders
          _isLoadingOrders
              ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
              : RefreshIndicator(
                  color: dharttiGreen,
                  onRefresh: _loadOrders,
                  child: _orders.isEmpty ? _buildEmptyOrders() : _buildOrdersList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: dharttiGreen.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.add_shopping_cart_rounded, size: 60, color: dharttiGreen),
            ),
            const SizedBox(height: 18),
            Text('No Products Listed Yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'List your construction materials, fittings, or hardware items to start selling on Dhartti Store.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditStoreProductScreen()),
                );
                if (res == true) _loadProducts();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('List First Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: dharttiGreen, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        final id = int.tryParse(p['id'].toString()) ?? 0;
        final name = p['name']?.toString() ?? 'Product';
        final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
        final stock = int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;
        final categoryName = p['category']?['name']?.toString() ?? 'Category';
        final imageUrl = _resolveProductImageUrl(p['image_url'] ?? p['image_path']);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: Colors.grey.shade100,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                          )
                        : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      const SizedBox(height: 2),
                      Text(categoryName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'PKR ${_currencyFormat.format(price)}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: dharttiGreen),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stock > 0 ? '$stock in stock' : 'Out of stock',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditStoreProductScreen(productToEdit: p as Map<String, dynamic>),
                          ),
                        );
                        if (res == true) _loadProducts();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deleteProduct(id, name),
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

  Widget _buildEmptyOrders() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: dharttiGreen.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 60, color: dharttiGreen),
            ),
            const SizedBox(height: 18),
            Text('No Store Orders Yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'When customers purchase your listed store items, their orders and delivery details will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final id = int.tryParse(order['id']?.toString() ?? '0') ?? 0;
        final customerName = order['customer_name']?.toString() ?? 'Customer';
        final phone = order['phone']?.toString() ?? '';
        final address = order['shipping_address']?.toString() ?? 'Address not specified';
        final status = order['status']?.toString() ?? 'Pending';
        final total = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
        final date = order['created_at']?.toString() ?? '';
        final items = (order['items'] as List?) ?? [];

        Color statusColor;
        switch (status) {
          case 'Processing':
            statusColor = Colors.orange;
            break;
          case 'Delivered':
          case 'Completed':
            statusColor = dharttiGreen;
            break;
          case 'Cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.blue;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID & Status Header
                Row(
                  children: [
                    Text('Order #$id', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                Text(date, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                const Divider(height: 20),

                // Customer Info
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(customerName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(phone, style: GoogleFonts.poppins(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(address, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order Items
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: items.map<Widget>((it) {
                      final pName = it['product_name'] ?? 'Item';
                      final qty = it['quantity'] ?? 1;
                      final pr = it['price'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$qty x ', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: dharttiGreen)),
                            Expanded(child: Text(pName.toString(), style: GoogleFonts.poppins(fontSize: 12))),
                            Text('PKR ${_currencyFormat.format(pr)}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Footer Total & Status Action Button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                        Text('PKR ${_currencyFormat.format(total)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: dharttiGreen)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showOrderStatusDialog(id, status),
                      icon: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.white),
                      label: Text('Change Status', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dharttiGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
