import 'package:dhartti/Model/store_model.dart';
import 'package:dhartti/UserScreen/Store/CartScreen.dart';
import 'package:dhartti/UserScreen/Store/CheckoutScreen.dart';
import 'package:dhartti/service/store_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final StoreProduct? initialProduct;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    this.initialProduct,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final StoreService _storeService = StoreService();

  StoreProduct? _product;
  List<StoreProduct> _recommended = [];
  bool _isLoading = true;
  int _selectedQuantity = 1;
  bool _isDescriptionExpanded = false;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAF8);

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() => _isLoading = _product == null);
    final data = await _storeService.fetchProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        if (data != null) {
          _product = data['product'] as StoreProduct;
          _recommended = data['recommended'] as List<StoreProduct>;
        }
        _isLoading = false;
      });
    }
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Write a Review",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your Rating:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() => selectedRating = star);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Share your experience with this material...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;

                        setDialogState(() => isSubmitting = true);
                        final prefs = await SharedPreferences.getInstance();
                        final dynamic rawUserId = prefs.get('userId');
                        final int? userId = rawUserId is int
                            ? rawUserId
                            : (rawUserId is String ? int.tryParse(rawUserId) : null);

                        final success = await _storeService.submitReview(
                          productId: widget.productId,
                          rating: selectedRating,
                          comment: text,
                          userId: userId,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "Review submitted successfully!" : "Could not submit review"),
                              backgroundColor: success ? dharttiGreen : Colors.redAccent,
                            ),
                          );
                          if (success) _loadProductDetail();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _product == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: dharttiGreen)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text("Product not found")),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: lightBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image App Bar
              _buildSliverAppBar(product),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Stock Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: dharttiGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.categoryName,
                              style: const TextStyle(
                                color: dharttiGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.hasDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${product.discountPercent}% OFF",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: product.isInStock
                                  ? const Color(0xFFE8F7EC)
                                  : const Color(0xFFFFECEB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isInStock ? Icons.check_circle : Icons.cancel,
                                  size: 13,
                                  color: product.isInStock ? dharttiGreen : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.isInStock
                                      ? "In Stock (${product.stockQuantity})"
                                      : "Out of Stock",
                                  style: TextStyle(
                                    color: product.isInStock ? dharttiGreen : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Georgia',
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Rating & Reviews Count
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            product.ratingAvg > 0 ? product.ratingAvg.toStringAsFixed(1) : "New",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(${product.reviewsCount} verified reviews)",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price Block
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "PKR ${product.effectivePrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: dharttiGreen,
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        "PKR ${product.price.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Save PKR ${(product.price - product.effectivePrice).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // Quantity Selector
                            if (product.isInStock)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (_selectedQuantity > 1) {
                                          setState(() => _selectedQuantity--);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.remove, size: 18),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        "$_selectedQuantity",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (_selectedQuantity < product.stockQuantity) {
                                          setState(() => _selectedQuantity++);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(Icons.add, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Dhartti Assurances
                      _buildAssuranceRow(),

                      const SizedBox(height: 20),

                      // Description
                      _buildDescriptionSection(product),

                      const SizedBox(height: 20),

                      // Reviews Section
                      _buildReviewsSection(product),

                      const SizedBox(height: 24),

                      // Recommended Products
                      if (_recommended.isNotEmpty) ...[
                        const Text(
                          "Related Materials",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Georgia',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendedList(),
                      ],

                      const SizedBox(height: 120), // Bottom bar padding
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(product),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(StoreProduct product) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: CartManager.instance,
          builder: (context, _) {
            final count = CartManager.instance.totalCount;
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: dharttiGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: InteractiveViewer(
          child: Container(
            color: Colors.grey.shade100,
            child: product.displayImageUrl.isNotEmpty
                ? Image.network(
                    product.displayImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.construction_rounded, size: 80, color: Colors.grey),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.construction_rounded, size: 80, color: Colors.grey),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssuranceRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dharttiGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAssuranceItem(Icons.verified_outlined, "100% Genuine"),
          _buildAssuranceItem(Icons.local_shipping_outlined, "Site Delivery"),
          _buildAssuranceItem(Icons.price_check_outlined, "Best Market Rates"),
        ],
      ),
    );
  }

  Widget _buildAssuranceItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: dharttiGreen),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(StoreProduct product) {
    final desc = product.description.isNotEmpty
        ? product.description
        : "Standard premium quality construction material supplied directly by authorized Dhartti manufacturers and distributors for building, civil works, and infrastructure.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description & Specifications",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: _isDescriptionExpanded ? 100 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5),
          ),
          if (desc.length > 120) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              child: Text(
                _isDescriptionExpanded ? "Show Less" : "Read More",
                style: const TextStyle(
                  color: dharttiGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection(StoreProduct product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Customer Reviews",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.rate_review_outlined, size: 16, color: dharttiGreen),
                label: const Text(
                  "Write Review",
                  style: TextStyle(color: dharttiGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (product.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No reviews yet. Be the first to review this product!",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: product.reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final r = product.reviews[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recommended.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _recommended[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: item.id, initialProduct: item),
                ),
              );
            },
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Container(
                        color: Colors.grey.shade100,
                        width: double.infinity,
                        child: item.displayImageUrl.isNotEmpty
                            ? Image.network(item.displayImageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.construction_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "PKR ${item.effectivePrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: dharttiGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar(StoreProduct product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add to Cart Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: !product.isInStock
                      ? null
                      : () {
                          CartManager.instance.addToCart(product, quantity: _selectedQuantity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Added $_selectedQuantity item(s) to Cart!"),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: "View Cart",
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: dharttiGreen, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_shopping_cart_rounded, color: dharttiGreen, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Add to Cart",
                        style: TextStyle(
                          color: dharttiGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Buy Now Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: !product.isInStock
                      ? null
                      : () {
                          CartManager.instance.addToCart(product, quantity: _selectedQuantity);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Buy Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
