import 'dart:convert';
import 'package:dhartti/Model/PropertyInquiry.dart';
import 'package:dhartti/Model/superproperty_model.dart';
import 'package:dhartti/service/AnalyticService.dart';
import 'package:dhartti/service/PropertyInquiryService.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/service/favorite_service.dart';
import 'package:dhartti/UserScreen/Chat/ChatConversationScreen.dart';
import 'package:dhartti/service/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/UserScreen/Chat/ChatInboxScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhartti/service/share_helper.dart';

class PropertyDetailPage extends StatefulWidget {
  final int propertyId;

  const PropertyDetailPage({Key? key, required this.propertyId}) : super(key: key);

  @override
  _PropertyDetailPageState createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  late Future<PropertySuperAdmin> _propertyFuture;
  final PropertyService _propertyService = PropertyService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();

  late final PageController _pageController;
  final ScrollController _thumbnailScrollController = ScrollController();

  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  bool _isFavorite = false;
  String? _selectedInquiryType;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAF8);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchData();
    _trackView();
    _checkInitialFavorite();
  }

  Future<void> _checkInitialFavorite() async {
    final isFav = await FavoriteService().isPropertyFavorite(widget.propertyId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  void _trackView() {
    try {
      _analyticsService.updateViews(widget.propertyId);
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    setState(() {
      _propertyFuture = _propertyService.fetchProperty(widget.propertyId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getValidImages(PropertySuperAdmin property) {
    final List<String> list = [];
    void addIfValid(dynamic url) {
      if (url == null) return;
      if (url is List) {
        for (var item in url) {
          addIfValid(item);
        }
        return;
      }
      final str = url.toString().trim();
      if (str.isEmpty || str == 'null' || str == '[]' || str == '{}') return;
      final formatted = PropertyService.formatPropertyImageUrl(str);
      if (formatted.isNotEmpty && !list.contains(formatted)) {
        list.add(formatted);
      }
    }

    if (property.allImages.isNotEmpty) {
      for (final img in property.allImages) {
        addIfValid(img);
      }
    }

    addIfValid(property.imagePath);
    addIfValid(property.imagePath2);
    addIfValid(property.imagePath3);
    addIfValid(property.imagePath4);
    addIfValid(property.imagePath5);
    return list;
  }

  void _scrollToThumbnail(int index) {
    if (_thumbnailScrollController.hasClients) {
      final double target = (index * 82.0) - 80;
      _thumbnailScrollController.animateTo(
        target.clamp(0.0, _thumbnailScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatPrice(dynamic priceVal, String? purpose) {
    if (priceVal == null) return "PKR Price on Call";
    double price = 0.0;
    if (priceVal is num) {
      price = priceVal.toDouble();
    } else {
      final clean = priceVal.toString().replaceAll(',', '').replaceAll('PKR', '').replaceAll('Rs', '').trim();
      price = double.tryParse(clean) ?? 0.0;
    }
    if (price <= 0) return "PKR Price on Call";

    final isRent = (purpose ?? '').toLowerCase().contains('rent');
    final suffix = isRent ? " / mo" : "";

    if (price >= 10000000) {
      double crore = price / 10000000;
      String formatted = crore.toStringAsFixed(crore.truncateToDouble() == crore ? 0 : 2);
      return "PKR $formatted Crore$suffix";
    } else if (price >= 100000) {
      double lac = price / 100000;
      String formatted = lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2);
      return "PKR $formatted Lakh$suffix";
    } else {
      final intPrice = price.toInt();
      final str = intPrice.toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
      return "PKR $formatted$suffix";
    }
  }

  String _getPhoneNumber(PropertySuperAdmin property) {
    if (property.mobileNumbers != null) {
      final str = property.mobileNumbers
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('\\', '')
          .trim();
      if (str.isNotEmpty && str != 'null') {
        return str.split(',').first.trim();
      }
    }
    if (property.landline != null && property.landline!.trim().isNotEmpty && property.landline != 'null') {
      return property.landline!.trim();
    }
    if (property.whatsappNumber != null && property.whatsappNumber!.trim().isNotEmpty && property.whatsappNumber != 'null') {
      return property.whatsappNumber!.trim();
    }
    return '';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty || phoneNumber.trim() == 'null') {
      _showSnackBar("Phone number not available", isError: true);
      return;
    }
    _analyticsService.updateCallClicks(widget.propertyId);

    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse("tel:$clean");
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        _showSnackBar("Could not initiate phone call", isError: true);
      }
    } catch (_) {
      _showSnackBar("Could not initiate phone call", isError: true);
    }
  }

  Future<void> _launchWhatsApp(String rawNumber, String title) async {
    final numberToUse = rawNumber.trim();
    if (numberToUse.isEmpty || numberToUse == 'null') {
      _showSnackBar("WhatsApp number not available for this listing", isError: true);
      return;
    }

    _analyticsService.updateWhatsAppClicks(widget.propertyId);

    var clean = numberToUse.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0092')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    } else if (clean.length == 10 && clean.startsWith('3')) {
      clean = '92$clean';
    }

    if (clean.length < 10) {
      _showSnackBar("Invalid WhatsApp number: $rawNumber", isError: true);
      return;
    }

    final msg = Uri.encodeComponent("Hello! I am interested in your property listing: '$title' on Dhartti.");
    final waMeUri = Uri.parse("https://wa.me/$clean?text=$msg");
    final apiWaUri = Uri.parse("https://api.whatsapp.com/send?phone=$clean&text=$msg");

    bool launched = false;
    try {
      launched = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(apiWaUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched) {
      _showSnackBar("Could not open WhatsApp. Please check if WhatsApp is installed.", isError: true);
    }
  }

  Future<void> _shareProperty({
    required String title,
    required String city,
    required String price,
    String? imageUrl,
    String? area,
    String? beds,
    String? baths,
    String? type,
    String? purpose,
  }) async {
    await ShareHelper.shareProperty(
      context: context,
      propertyId: widget.propertyId,
      title: title,
      city: city,
      price: price,
      imageUrl: imageUrl,
      area: area,
      beds: beds,
      baths: baths,
      type: type,
      purpose: purpose,
    );
  }

  Future<void> _submitInquiry() async {
    if (_formKey.currentState!.validate() && _selectedInquiryType != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic rawUserId = prefs.get('userId');
        final int? userId = rawUserId is int
            ? rawUserId
            : (rawUserId is String ? int.tryParse(rawUserId) : null);

        if (userId == null) {
          throw Exception('Please login first to submit an inquiry');
        }

        final inquiry = PropertyInquiry(
          propertyId: widget.propertyId,
          message: _messageController.text,
          inquiryType: _selectedInquiryType!,
        );

        final success = await PropertyInquiryService().submitInquiry(inquiry);

        if (success) {
          _showSnackBar('Inquiry submitted successfully! The owner will contact you.');
          _messageController.clear();
          setState(() {
            _selectedInquiryType = null;
          });
        } else {
          _showSnackBar('Could not submit inquiry. Please try again.', isError: true);
        }
      } catch (e) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      _showSnackBar('Please type a message and select an inquiry type.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : dharttiGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _scrollToInquiry() {
    Scrollable.ensureVisible(
      _inquiryKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: FutureBuilder<PropertySuperAdmin>(
        future: _propertyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: dharttiGreen),
                  SizedBox(height: 16),
                  Text("Loading property details...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text('Failed to load property', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dharttiGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Property not found.'));
          }

          final property = snapshot.data!;
          final images = _getValidImages(property);
          if (_currentImageIndex >= images.length) {
            _currentImageIndex = 0;
          }
          final title = property.title ?? 'Luxury Property';
          final plotNo = (property.plotNumber != null && property.plotNumber!.trim().isNotEmpty) ? property.plotNumber!.trim() : '';
          final cityName = (property.city != null && property.city!.trim().isNotEmpty) ? property.city!.trim() : 'Location not specified';
          final city = plotNo.isNotEmpty ? '$plotNo, $cityName' : cityName;
          final purpose = (property.purpose ?? 'Sell').toString();
          final subType = (property.subPropertyType ?? property.propertyType ?? 'Property').toString();
          final priceDisplay = _formatPrice(property.price, purpose);
          final phoneNumber = _getPhoneNumber(property);
          final whatsappNumber = (property.whatsappNumber != null &&
                  property.whatsappNumber!.trim().isNotEmpty &&
                  property.whatsappNumber != 'null')
              ? property.whatsappNumber!.trim()
              : phoneNumber;

          return Stack(
            children: [
              // Main Scrollable Content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Sleek Sliver Hero Image Slider with Manual Controls
                  SliverAppBar(
                    expandedHeight: 330,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.92),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.92),
                          child: IconButton(
                            icon: const Icon(Icons.share_outlined, size: 20, color: Colors.black87),
                            onPressed: () => _shareProperty(
                              title: title,
                              city: city,
                              price: priceDisplay,
                              imageUrl: images.isNotEmpty ? images.first : null,
                              area: (property.areaSize != null && property.areaSize.toString().isNotEmpty)
                                  ? '${property.areaSize} ${property.areaUnit ?? ''}'.trim()
                                  : null,
                              beds: property.bedrooms?.toString(),
                              baths: property.bathrooms?.toString(),
                              type: subType,
                              purpose: purpose,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0, left: 4.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.92),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 20,
                              color: _isFavorite ? Colors.redAccent : Colors.black87,
                            ),
                            onPressed: () async {
                              final propertyMap = {
                                'id': property.id,
                                'title': property.title,
                                'city': property.city,
                                'plot_number': property.plotNumber ?? '',
                                'sub_property_type': property.subPropertyType,
                                'price': property.price,
                                'area_size': property.areaSize,
                                'area_unit': property.areaUnit,
                                'bedrooms': property.bedrooms,
                                'bathrooms': property.bathrooms,
                                'property_type': property.propertyType,
                                'purpose': property.purpose,
                                'image_path': images.isNotEmpty ? images.first : '',
                              };
                              final isNowFav = await FavoriteService().togglePropertyFavorite(propertyMap);
                              setState(() {
                                _isFavorite = isNowFav;
                              });
                              _showSnackBar(isNowFav ? "Added to favourites!" : "Removed from favourites");
                            },
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Interactive PageView with Manual Swipe
                          images.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: images.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                    _scrollToThumbnail(index);
                                  },
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _openImageLightbox(context, images, index),
                                      child: Hero(
                                        tag: "property_hero_$index",
                                        child: Image.network(
                                          images[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (c, e, s) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: const Color(0xFFF1F5F2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.home_work_outlined, size: 64, color: dharttiGreen),
                                      SizedBox(height: 8),
                                      Text("Dhartti Verified Property", style: TextStyle(color: dharttiGreen, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),

                          // Subtle Vignette Overlay for Badges Contrast
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Manual Navigation Arrows (Left & Right)
                          if (images.length > 1 && _currentImageIndex > 0)
                            Positioned(
                              left: 12,
                              top: 155,
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.48),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 0.8),
                                  ),
                                  child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          if (images.length > 1 && _currentImageIndex < images.length - 1)
                            Positioned(
                              right: 12,
                              top: 155,
                              child: GestureDetector(
                                onTap: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.48),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 0.8),
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ),

                          // Image Counter Pill (Bottom Right)
                          if (images.length > 1)
                            Positioned(
                              bottom: 24,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _openImageLightbox(context, images, _currentImageIndex),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${_currentImageIndex + 1} / ${images.length}",
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Badges on Hero Image (Purpose & Verified)
                          Positioned(
                            bottom: 24,
                            left: 16,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: dharttiGreen,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Text(
                                    "FOR ${purpose.toUpperCase()}",
                                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24, width: 0.8),
                                  ),
                                  child: Text(
                                    subType,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Main Content Card with Thumbnail Bar Directly Underneath
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Gallery Selector Row (Directly below main photo)
                          if (images.isNotEmpty)
                            _buildThumbnailSelectorBar(images),

                          // Price & Header Section
                          _buildPriceAndTitleSection(property, priceDisplay, title, city, subType),

                          // Key Specs Quick Strip (Beds, Baths, Area)
                          _buildKeySpecificationsStrip(property, subType),

                          // Property Overview Table
                          _buildPropertyOverviewSection(property),

                          // Description
                          _buildDescriptionSection(property),

                          // Amenities / Features Grid
                          _buildAmenitiesSection(property),

                          // Financial / Installments Details
                          if (property.installmentAvailable == true)
                            _buildInstallmentSummaryCard(property),

                          // Agent / Listed By Card
                          _buildAgentContactCard(property, phoneNumber, whatsappNumber, title),

                          // Interactive Inquiry Form
                          _buildInquiryCardSection(),

                          // Bottom safe area spacer for floating CTA bar
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Quick-Action Bar
              _buildFloatingBottomBar(phoneNumber, whatsappNumber, title, property),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // THUMBNAIL SELECTOR BAR (DIRECTLY BELOW HERO)
  // ==========================================
  Widget _buildThumbnailSelectorBar(List<String> images) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library_outlined, size: 15, color: dharttiGreen),
                  const SizedBox(width: 6),
                  Text(
                    "Photos (${_currentImageIndex + 1}/${images.length}) • Tap to View",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openImageLightbox(context, images, _currentImageIndex),
                child: Row(
                  children: const [
                    Icon(Icons.fullscreen_rounded, size: 16, color: dharttiGreen),
                    SizedBox(width: 3),
                    Text(
                      "Fullscreen",
                      style: TextStyle(
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
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.builder(
              controller: _thumbnailScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              itemBuilder: (context, idx) {
                final isSelected = _currentImageIndex == idx;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    setState(() {
                      _currentImageIndex = idx;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? dharttiGreen : Colors.grey.shade300,
                        width: isSelected ? 2.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: dharttiGreen.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9.5),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 24, color: Colors.grey),
                            ),
                          ),
                          if (!isSelected)
                            Container(
                              color: Colors.white.withOpacity(0.18),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: PRICE, TITLE, LOCATION
  // ==========================================
  Widget _buildPriceAndTitleSection(PropertySuperAdmin property, String priceDisplay, String title, String city, String subType) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                priceDisplay,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: dharttiGreen,
                  letterSpacing: -0.5,
                ),
              ),
              if (property.installmentAvailable == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.credit_card_rounded, size: 13, color: dharttiGreen),
                      SizedBox(width: 4),
                      Text("Installments", style: TextStyle(color: dharttiGreen, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B221D),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: dharttiGreen),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  city,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text("4.8", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: KEY SPECIFICATIONS STRIP
  // ==========================================
  Widget _buildKeySpecificationsStrip(PropertySuperAdmin property, String subType) {
    final int beds = property.bedrooms ?? 0;
    final int baths = property.bathrooms ?? 0;
    final String areaSize = (property.areaSize ?? '').toString();
    final String areaUnit = (property.areaUnit ?? 'Sq. Ft.').toString();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Highlights", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A221C))),
          const SizedBox(height: 12),
          Row(
            children: [
              if (beds > 0)
                Expanded(child: _buildSpecCard(Icons.bed_rounded, "$beds Beds", "Bedrooms")),
              if (beds > 0) const SizedBox(width: 10),
              if (baths > 0)
                Expanded(child: _buildSpecCard(Icons.bathtub_rounded, "$baths Baths", "Bathrooms")),
              if (baths > 0) const SizedBox(width: 10),
              if (areaSize.isNotEmpty && areaSize != '0')
                Expanded(child: _buildSpecCard(Icons.square_foot_rounded, "$areaSize $areaUnit", "Area")),
              if (beds == 0 && baths == 0)
                Expanded(child: _buildSpecCard(Icons.apartment_rounded, subType, "Category")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBE5), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: dharttiGreen),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF202B22)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: OVERVIEW DETAILS MATRIX
  // ==========================================
  Widget _buildPropertyOverviewSection(PropertySuperAdmin property) {
    final Map<String, String> items = {
      'Type': property.propertyType ?? 'Residential',
      'Sub Category': property.subPropertyType ?? 'House',
      'Purpose': (property.purpose ?? 'Sell').toUpperCase(),
      'City': property.city ?? 'Not specified',
      'Area': "${property.areaSize ?? 'N/A'} ${property.areaUnit ?? ''}",
      'Ready For Possession': (property.readyForPossession == true) ? 'Yes' : 'No',
      'Installment Option': (property.installmentAvailable == true) ? 'Available' : 'Lump Sum',
      'Currency': property.currency ?? 'PKR',
    };

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Property Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B221D))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.entries.map((entry) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: dharttiGreen),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF222B24))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: DESCRIPTION
  // ==========================================
  Widget _buildDescriptionSection(PropertySuperAdmin property) {
    final desc = property.description ?? 'No detailed description available for this property.';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B221D))),
          const SizedBox(height: 10),
          Text(
            desc,
            maxLines: _isDescriptionExpanded ? null : 4,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
          ),
          if (desc.length > 160)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _isDescriptionExpanded ? "Read Less" : "Read More...",
                  style: const TextStyle(color: dharttiGreen, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: AMENITIES & FEATURES
  // ==========================================
  Widget _buildAmenitiesSection(PropertySuperAdmin property) {
    List<String> amenitiesList = [];
    if (property.amenities != null) {
      if (property.amenities is List) {
        amenitiesList = (property.amenities as List).map((e) => e.toString()).toList();
      } else if (property.amenities is String) {
        final str = property.amenities.toString();
        if (str.startsWith('[')) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is List) {
              amenitiesList = decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }
        if (amenitiesList.isEmpty && str.isNotEmpty) {
          amenitiesList = str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    }

    if (amenitiesList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Amenities & Features", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B221D))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenitiesList.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3E9E3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: dharttiGreen),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF202A22)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: INSTALLMENT SUMMARY
  // ==========================================
  Widget _buildInstallmentSummaryCard(PropertySuperAdmin property) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payment_rounded, color: dharttiGreen, size: 20),
              SizedBox(width: 8),
              Text("Payment Plan Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B221D))),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE2)),
            ),
            child: Column(
              children: [
                if (property.advanceAmount != null)
                  _buildPaymentRow("Advance / Down Payment", "PKR ${property.advanceAmount}"),
                if (property.monthlyInstallment != null) ...[
                  const Divider(height: 16),
                  _buildPaymentRow("Monthly Installment", "PKR ${property.monthlyInstallment}"),
                ],
                const Divider(height: 16),
                _buildPaymentRow("Possession", (property.readyForPossession == true) ? "Immediate" : "On Completion"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dharttiGreen)),
      ],
    );
  }

  // ==========================================
  // SECTION: AGENT / LISTED BY CARD
  // ==========================================
  Widget _buildAgentContactCard(PropertySuperAdmin property, String phoneNumber, String whatsappNumber, String title) {
    final agentName = (property.username != null && property.username!.trim().isNotEmpty && property.username != 'null')
        ? property.username!.trim()
        : "Dhartti Property Partner";

    final displayPhone = phoneNumber.isNotEmpty ? phoneNumber : 'Contact Available';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Listed By",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dharttiGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 12, color: dharttiGreen),
                    const SizedBox(width: 4),
                    Text(
                      "Verified Listing",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dharttiGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  agentName.isNotEmpty ? agentName[0].toUpperCase() : 'D',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            agentName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF0284C7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          displayPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(phoneNumber),
                  icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
                  label: Text(
                    "Call",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchWhatsApp(whatsappNumber, title),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF107C38)),
                  label: Text(
                    "WhatsApp",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF107C38),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F7EC),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openChat(property),
              icon: const Icon(Icons.forum_rounded, size: 16, color: dharttiGreen),
              label: Text(
                "Direct In-App Chat",
                style: GoogleFonts.poppins(
                  color: dharttiGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: dharttiGreen.withValues(alpha: 0.05),
                side: const BorderSide(color: dharttiGreen, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION: INQUIRY FORM
  // ==========================================
  Widget _buildInquiryCardSection() {
    return Container(
      key: _inquiryKey,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Have Questions?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B221D))),
          const SizedBox(height: 4),
          Text("Send an inquiry directly to the agent or management.", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message (e.g. Is this still available? Can I visit tomorrow?)...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please type your question or message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text("I am a:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInquiryChip('buyer', 'Buyer / Tenant'),
                    const SizedBox(width: 8),
                    _buildInquiryChip('agent', 'Real Estate Agent'),
                    const SizedBox(width: 8),
                    _buildInquiryChip('other', 'Other'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dharttiGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("SUBMIT INQUIRY", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryChip(String value, String label) {
    final isSelected = _selectedInquiryType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInquiryType = isSelected ? null : value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? dharttiGreen : const Color(0xFFF5F7F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? dharttiGreen : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FLOATING BOTTOM CONVERSION BAR
  // ==========================================

  Future<void> _openChat(PropertySuperAdmin property) async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawUserId = prefs.get('userId') ?? prefs.get('user_id');
    final int? userId = rawUserId is int ? rawUserId : int.tryParse(rawUserId?.toString() ?? '');

    if (userId == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Login Required", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text("Please log in to chat directly with property sellers and contractors.", style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: Text("Log In", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    int? sellerId = property.userId;
    if (sellerId == null || sellerId <= 0) {
      // Demo listings fallback to 1 (Admin/Support)
      sellerId = 1;
    }

    if (userId == sellerId) {
      _showSnackBar('Opening your Chat Inbox for this listing.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: dharttiGreen),
      ),
    );

    try {
      final res = await ChatService().initiateChat(
        sellerId: sellerId,
        propertyId: property.id,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final rawRoomId = res['room_id'] ?? res['id'];
      if (rawRoomId != null) {
        final roomId = int.tryParse(rawRoomId.toString()) ?? 0;
        final sellerName = res['other_user_name'] ?? property.username ?? 'Seller';
        final otherRole = res['other_user_role'] ?? 'Seller';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              roomId: roomId,
              otherUserName: sellerName,
              otherUserRole: otherRole,
              contextTitle: property.title,
              propertyId: property.id,
              propertyPrice: property.price?.toString(),
              propertyCity: property.city,
            ),
          ),
        );
      } else {
        _showSnackBar(res['message'] ?? 'Could not start chat conversation.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error initiating chat: $e');
      }
    }
  }


  Widget _buildFloatingBottomBar(String phoneNumber, String whatsappNumber, String title, PropertySuperAdmin property) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Inquire Quick Trigger
            InkWell(
              onTap: _scrollToInquiry,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.mail_outline_rounded, size: 20, color: dharttiGreen),
              ),
            ),
            const SizedBox(width: 8),

            // Chat with Seller
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(property),
                icon: const Icon(Icons.forum_rounded, size: 14, color: Colors.white),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B221D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Call Button
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(phoneNumber),
                icon: const Icon(Icons.call_rounded, size: 14, color: Colors.white),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // WhatsApp Button
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(whatsappNumber, title),
                icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.white),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // LIGHTBOX FULL SCREEN PHOTO MODAL
  // ==========================================
  void _openImageLightbox(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        int activeIdx = initialIndex;
        final lightboxController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (ctx, setLightboxState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
                title: Text(
                  "${activeIdx + 1} / ${images.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              body: Stack(
                children: [
                  PageView.builder(
                    controller: lightboxController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: images.length,
                    onPageChanged: (idx) {
                      setLightboxState(() {
                        activeIdx = idx;
                      });
                      setState(() {
                        _currentImageIndex = idx;
                      });
                      _scrollToThumbnail(idx);
                    },
                    itemBuilder: (context, idx) {
                      return Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: Image.network(
                            images[idx],
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Center(
                              child: Icon(Icons.broken_image, size: 60, color: Colors.white54),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Fullscreen Left Arrow
                  if (activeIdx > 0)
                    Positioned(
                      left: 14,
                      top: MediaQuery.of(context).size.height * 0.45,
                      child: GestureDetector(
                        onTap: () {
                          lightboxController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),

                  // Fullscreen Right Arrow
                  if (activeIdx < images.length - 1)
                    Positioned(
                      right: 14,
                      top: MediaQuery.of(context).size.height * 0.45,
                      child: GestureDetector(
                        onTap: () {
                          lightboxController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
