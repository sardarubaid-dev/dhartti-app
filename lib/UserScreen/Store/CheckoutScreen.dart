import 'package:dhartti/UserScreen/Store/MyOrdersScreen.dart';
import 'package:dhartti/service/store_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: "Islamabad / Rawalpindi");
  final TextEditingController _notesController = TextEditingController();

  String _paymentMethod = "cod"; // "cod" = Cash on Delivery
  bool _isSubmitting = false;
  int? _userId;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAF8);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawUserId = prefs.get('userId');
      _userId = rawUserId is int
          ? rawUserId
          : (rawUserId is String ? int.tryParse(rawUserId) : null);
      final savedName = prefs.getString('userName') ?? prefs.getString('name') ?? '';
      final savedEmail = prefs.getString('userEmail') ?? prefs.getString('email') ?? '';
      final savedPhone = prefs.getString('userPhone') ?? prefs.getString('phone') ?? '';

      if (savedName.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = savedName;
      }
      if (savedEmail.isNotEmpty && _emailController.text.isEmpty) {
        _emailController.text = savedEmail;
      }
      if (savedPhone.isNotEmpty && _phoneController.text.isEmpty) {
        _phoneController.text = savedPhone;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = CartManager.instance;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty. Please add items to proceed.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final fullAddress = "${_addressController.text.trim()}, ${_cityController.text.trim()}" +
        (_notesController.text.trim().isNotEmpty ? " (Note: ${_notesController.text.trim()})" : "");

    final res = await StoreService().placeOrder(
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      shippingAddress: fullAddress,
      items: cart.items,
      userId: _userId,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      final orderId = res['order_id'];
      try {
        if (orderId != null) {
          final prefs = await SharedPreferences.getInstance();
          final existing = prefs.getStringList('my_placed_order_ids') ?? [];
          if (!existing.contains(orderId.toString())) {
            existing.add(orderId.toString());
            await prefs.setStringList('my_placed_order_ids', existing);
          }
          await prefs.setString('userPhone', _phoneController.text.trim());
        }
      } catch (_) {}

      cart.clearCart();
      _showSuccessDialog((orderId ?? 'N/A').toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to place order'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: dharttiGreen, size: 56),
            ),
            const SizedBox(height: 18),
            const Text(
              "Order Placed Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                fontFamily: 'Georgia',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your Order #$orderId has been received. Our store manager will contact you soon for confirmation and delivery details.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Track My Order",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Back to store
              },
              child: const Text("Continue Shopping", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartManager.instance;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Shipping Information
              _buildSectionTitle(Icons.local_shipping_outlined, "Delivery Address"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name *",
                      hint: "Enter recipient's full name",
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty ? "Name is required" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _phoneController,
                      label: "Phone / WhatsApp Number *",
                      hint: "e.g. 03001234567",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().length < 10 ? "Valid phone number required" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address *",
                      hint: "e.g. buyer@example.com",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@') ? "Valid email required" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _cityController,
                      label: "City *",
                      hint: "e.g. Islamabad, Rawalpindi, Lahore",
                      icon: Icons.location_city_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? "City is required" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _addressController,
                      label: "Complete Street Address *",
                      hint: "Plot/House #, Street #, Sector / Society name",
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _notesController,
                      label: "Order Notes / Special Instructions",
                      hint: "e.g. Landmark, call before arrival",
                      icon: Icons.notes_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method
              _buildSectionTitle(Icons.payment_outlined, "Payment Method"),
              const SizedBox(height: 10),
              Container(
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: "cod",
                      groupValue: _paymentMethod,
                      activeColor: dharttiGreen,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                      title: const Text(
                        "Cash on Delivery (COD)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Pay in cash when materials are delivered to your site",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dharttiGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.money_rounded, color: dharttiGreen, size: 20),
                      ),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: "online",
                      groupValue: _paymentMethod,
                      activeColor: dharttiGreen,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                      title: const Text(
                        "Direct Bank Transfer / Online",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Bank account details will be shared on confirmation",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.blue, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order Summary Mini Box
              _buildSectionTitle(Icons.receipt_long_outlined, "Order Summary"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardBoxDecoration(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Items (${cart.totalCount})", style: const TextStyle(color: Colors.black54)),
                        Text("PKR ${cart.subtotal.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Delivery Charges", style: TextStyle(color: Colors.black54)),
                        Text(
                          cart.deliveryCharge == 0 ? "FREE" : "PKR ${cart.deliveryCharge.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: cart.deliveryCharge == 0 ? dharttiGreen : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Payable",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "PKR ${cart.grandTotal.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: dharttiGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Confirm & Place Order",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: dharttiGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        prefixIcon: Icon(icon, size: 20, color: dharttiGreen),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dharttiGreen, width: 1.5),
        ),
      ),
    );
  }

  BoxDecoration _cardBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
