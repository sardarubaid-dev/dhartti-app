import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/Appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhartti/service/share_helper.dart';
import 'package:dhartti/service/property_service.dart';
import 'package:dhartti/service/AnalyticService.dart';
import 'package:dhartti/service/favorite_service.dart';
import 'package:dhartti/UserScreen/Favourite.dart';

class PropertyListScreen extends StatefulWidget {
  final String? initialCity;
  final String? initialPurpose;
  final String? initialPropertyType;
  final String? initialBeds;
  final String? initialBaths;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final double? initialMinArea;
  final double? initialMaxArea;
  final String? initialKeyword;

  const PropertyListScreen({
    Key? key,
    this.initialCity,
    this.initialPurpose,
    this.initialPropertyType,
    this.initialBeds,
    this.initialBaths,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinArea,
    this.initialMaxArea,
    this.initialKeyword,
  }) : super(key: key);

  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  late Future<List<dynamic>> _properties;
  final AnalyticsService _analyticsService = AnalyticsService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedCity;
  String? _selectedPurpose;
  String? _selectedPropertyType;
  String? _selectedBeds;
  String? _selectedBaths;
  double? _minPrice;
  double? _maxPrice;
  double? _minArea;
  double? _maxArea;
  String _searchKeyword = '';
  final Set<dynamic> _favoritedIds = {};

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAF8);

  final List<String> _cities = [
    'All Cities',
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Peshawar',
    'Multan',
    'Gujranwala',
    'Quetta',
  ];

  final List<String> _propertyTypes = [
    'All Types',
    'House',
    'Flat',
    'Plot',
    'Commercial',
    'Penthouse',
    'Office',
    'Shop',
    'Room',
  ];

  @override
  void initState() {
    super.initState();
    _applyInitialFilters();
    _fetchProperties();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoriteService().getFavoriteProperties();
    if (mounted) {
      setState(() {
        _favoritedIds.clear();
        for (var f in favs) {
          if (f['id'] != null) _favoritedIds.add(f['id']);
        }
      });
    }
  }

  void _applyInitialFilters() {
    _selectedCity = widget.initialCity;
    _selectedPurpose = widget.initialPurpose;
    _selectedPropertyType = widget.initialPropertyType;
    _selectedBeds = widget.initialBeds;
    _selectedBaths = widget.initialBaths;
    _minPrice = widget.initialMinPrice;
    _maxPrice = widget.initialMaxPrice;
    _minArea = widget.initialMinArea;
    _maxArea = widget.initialMaxArea;
    if (widget.initialKeyword != null && widget.initialKeyword!.trim().isNotEmpty) {
      _searchKeyword = widget.initialKeyword!.trim();
      _searchController.text = _searchKeyword;
    }
  }

  @override
  void didUpdateWidget(covariant PropertyListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCity != oldWidget.initialCity ||
        widget.initialPurpose != oldWidget.initialPurpose ||
        widget.initialPropertyType != oldWidget.initialPropertyType ||
        widget.initialBeds != oldWidget.initialBeds ||
        widget.initialBaths != oldWidget.initialBaths ||
        widget.initialMinPrice != oldWidget.initialMinPrice ||
        widget.initialMaxPrice != oldWidget.initialMaxPrice ||
        widget.initialMinArea != oldWidget.initialMinArea ||
        widget.initialMaxArea != oldWidget.initialMaxArea ||
        widget.initialKeyword != oldWidget.initialKeyword) {
      _applyInitialFilters();
      _fetchProperties();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchProperties() {
    setState(() {
      _properties = PropertyService().fetchProperties(
        city: _selectedCity,
        purpose: _selectedPurpose,
        propertyType: _selectedPropertyType,
        beds: _selectedBeds,
        baths: _selectedBaths,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minArea: _minArea,
        maxArea: _maxArea,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
      );
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCity = null;
      _selectedPurpose = null;
      _selectedPropertyType = null;
      _selectedBeds = null;
      _selectedBaths = null;
      _minPrice = null;
      _maxPrice = null;
      _minArea = null;
      _maxArea = null;
      _searchKeyword = '';
      _searchController.clear();
      _fetchProperties();
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCity != null && _selectedCity!.isNotEmpty && _selectedCity != 'All Cities') count++;
    if (_selectedPurpose != null && _selectedPurpose!.isNotEmpty && _selectedPurpose != 'all') count++;
    if (_selectedPropertyType != null && _selectedPropertyType!.isNotEmpty && _selectedPropertyType != 'All Types') count++;
    if (_selectedBeds != null && _selectedBeds!.isNotEmpty && _selectedBeds != 'Any') count++;
    if (_selectedBaths != null && _selectedBaths!.isNotEmpty && _selectedBaths != 'Any') count++;
    if (_minPrice != null && _minPrice! > 0) count++;
    if (_maxPrice != null && _maxPrice! > 0) count++;
    if (_minArea != null && _minArea! > 0) count++;
    if (_maxArea != null && _maxArea! > 0) count++;
    if (_searchKeyword.isNotEmpty) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  double _parseNumericPrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    final clean = val.toString().replaceAll(',', '').replaceAll('PKR', '').replaceAll('Rs', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  String _formatPrice(dynamic priceVal, [String? purpose]) {
    double price = _parseNumericPrice(priceVal);
    if (price <= 0) return "PKR Price on Call";

    final isRent = (purpose ?? _selectedPurpose ?? '').toLowerCase().contains('rent');
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

  Future<void> _showSaveSearchModal() async {
    List<String> parts = [];
    if (_selectedCity != null && _selectedCity != 'All Cities') parts.add(_selectedCity!);
    if (_selectedPropertyType != null && _selectedPropertyType != 'All Types') parts.add(_selectedPropertyType!);
    if (_selectedPurpose != null && _selectedPurpose != 'all') parts.add('For ${_selectedPurpose!.toUpperCase()}');
    if (_selectedBeds != null && _selectedBeds != 'Any') parts.add('${_selectedBeds} Beds');
    if (_searchKeyword.isNotEmpty) parts.add('"$_searchKeyword"');
    if (parts.isEmpty) parts.add("All Properties");
    final String defaultTitle = parts.join(' • ');

    final TextEditingController nameController = TextEditingController(text: defaultTitle);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: dharttiGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bookmark_add_rounded, color: dharttiGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Save Search",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          "Get quick access to these property filters anytime",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                "Search Name",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Enter a name for this search...",
                  prefixIcon: const Icon(Icons.edit_outlined, size: 18, color: dharttiGreen),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: dharttiGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Active Filter Criteria",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_selectedCity != null && _selectedCity != 'All Cities')
                    _buildSaveFilterChip("City: $_selectedCity"),
                  if (_selectedPurpose != null && _selectedPurpose != 'all')
                    _buildSaveFilterChip("Purpose: ${_selectedPurpose!.toUpperCase()}"),
                  if (_selectedPropertyType != null && _selectedPropertyType != 'All Types')
                    _buildSaveFilterChip("Type: $_selectedPropertyType"),
                  if (_selectedBeds != null && _selectedBeds != 'Any')
                    _buildSaveFilterChip("Beds: $_selectedBeds"),
                  if (_selectedBaths != null && _selectedBaths != 'Any')
                    _buildSaveFilterChip("Baths: $_selectedBaths"),
                  if (_maxPrice != null && _maxPrice! > 0)
                    _buildSaveFilterChip("Max: ${_formatPrice(_maxPrice)}"),
                  if (_minPrice != null && _minPrice! > 0)
                    _buildSaveFilterChip("Min: ${_formatPrice(_minPrice)}"),
                  if (_searchKeyword.isNotEmpty)
                    _buildSaveFilterChip("Keyword: $_searchKeyword"),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    "Save to Favourites",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final title = nameController.text.trim().isEmpty ? defaultTitle : nameController.text.trim();
                    await FavoriteService().saveSearch(
                      title: title,
                      city: _selectedCity,
                      purpose: _selectedPurpose,
                      propertyType: _selectedPropertyType,
                      beds: _selectedBeds,
                      baths: _selectedBaths,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      minArea: _minArea,
                      maxArea: _maxArea,
                      keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
                    );
                    Navigator.pop(modalCtx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Row(
                            children: [
                              const Icon(Icons.bookmark_added_rounded, color: dharttiGreen, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Search '$title' saved!",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          action: SnackBarAction(
                            label: "VIEW",
                            textColor: dharttiGreen,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FavouriteScreen(initialTabIndex: 1)),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveFilterChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
      ),
    );
  }

  Future<void> _launchWhatsApp(String whatsappNumber) async {
    if (whatsappNumber.trim().isEmpty) return;
    var clean = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0092')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = '92${clean.substring(1)}';
    }
    if (clean.isEmpty) return;

    final nativeUri = Uri.parse("whatsapp://send?phone=$clean");
    final webUri = Uri.parse("https://wa.me/$clean");
    final altUri = Uri.parse("https://api.whatsapp.com/send?phone=$clean");

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      await launchUrl(altUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse("tel:$clean");
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          _selectedCity != null && _selectedCity!.isNotEmpty && _selectedCity != 'All Cities'
              ? "Properties in $_selectedCity"
              : (_selectedPurpose != null && _selectedPurpose != 'all'
                  ? "For ${_selectedPurpose!.toUpperCase()}"
                  : "All Properties"),
          style: TextStyle(
            color: Colors.black87,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: dharttiGreen),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.tune_rounded, color: dharttiGreen, size: 26),
                if (_hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: "Filter Properties",
            onPressed: _openFilterBottomSheet,
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: DrawerScreen(),
      body: Column(
        children: [
          // 1. Search Bar & Filter Quick Trigger
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F6F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (val) {
                        setState(() {
                          _searchKeyword = val.trim();
                          _fetchProperties();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search title, location, keywords...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 20, color: dharttiGreen),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, size: 16, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchKeyword = '';
                                    _fetchProperties();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: _openFilterBottomSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 44,
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? dharttiGreen : dharttiGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dharttiGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: _hasActiveFilters ? Colors.white : dharttiGreen,
                        ),
                        SizedBox(width: 5),
                        Text(
                          _hasActiveFilters ? "Filters ($_activeFilterCount)" : "Filter",
                          style: TextStyle(
                            color: _hasActiveFilters ? Colors.white : dharttiGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Horizontal Active Filter Chips
          if (_hasActiveFilters)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showSaveSearchModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: dharttiGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: dharttiGreen.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_add_outlined, size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              "Save Search",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedPurpose != null && _selectedPurpose!.isNotEmpty && _selectedPurpose != 'all')
                      _buildActiveChip("For ${_selectedPurpose!.toUpperCase()}", () {
                        setState(() { _selectedPurpose = null; _fetchProperties(); });
                      }),
                    if (_selectedCity != null && _selectedCity!.isNotEmpty && _selectedCity != 'All Cities')
                      _buildActiveChip("City: $_selectedCity", () {
                        setState(() { _selectedCity = null; _fetchProperties(); });
                      }),
                    if (_selectedPropertyType != null && _selectedPropertyType!.isNotEmpty && _selectedPropertyType != 'All Types')
                      _buildActiveChip("Type: $_selectedPropertyType", () {
                        setState(() { _selectedPropertyType = null; _fetchProperties(); });
                      }),
                    if (_selectedBeds != null && _selectedBeds!.isNotEmpty && _selectedBeds != 'Any')
                      _buildActiveChip("Beds: $_selectedBeds", () {
                        setState(() { _selectedBeds = null; _fetchProperties(); });
                      }),
                    if (_selectedBaths != null && _selectedBaths!.isNotEmpty && _selectedBaths != 'Any')
                      _buildActiveChip("Baths: $_selectedBaths", () {
                        setState(() { _selectedBaths = null; _fetchProperties(); });
                      }),
                    if (_maxPrice != null && _maxPrice! > 0)
                      _buildActiveChip("Max Price: ${_formatPrice(_maxPrice)}", () {
                        setState(() { _maxPrice = null; _fetchProperties(); });
                      }),
                    if (_minPrice != null && _minPrice! > 0)
                      _buildActiveChip("Min Price: ${_formatPrice(_minPrice)}", () {
                        setState(() { _minPrice = null; _fetchProperties(); });
                      }),
                    if (_maxArea != null && _maxArea! > 0)
                      _buildActiveChip("Max Area: ${_maxArea!.toInt()}", () {
                        setState(() { _maxArea = null; _fetchProperties(); });
                      }),
                    if (_searchKeyword.isNotEmpty)
                      _buildActiveChip("Keyword: $_searchKeyword", () {
                        setState(() {
                          _searchKeyword = '';
                          _searchController.clear();
                          _fetchProperties();
                        });
                      }),
                    InkWell(
                      onTap: _clearAllFilters,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text("Reset All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // 3. Properties List View
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _properties,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: dharttiGreen),
                        SizedBox(height: 16),
                        Text("Loading properties...", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                          Icon(Icons.cloud_off, size: 54, color: Colors.grey.shade400),
                          SizedBox(height: 12),
                          Text('Failed to load properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: dharttiGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: _fetchProperties,
                            child: Text("Retry", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Robust client-side filter pass
                List<dynamic> list = List.from(snapshot.data!);

                if (_selectedCity != null && _selectedCity!.isNotEmpty && _selectedCity!.toLowerCase() != 'all cities') {
                  list = list.where((item) {
                    final c = (item['city'] ?? '').toString().toLowerCase().trim();
                    return c.contains(_selectedCity!.toLowerCase().trim());
                  }).toList();
                }

                if (_selectedPurpose != null && _selectedPurpose!.isNotEmpty && _selectedPurpose!.toLowerCase() != 'all') {
                  list = list.where((item) {
                    final p = (item['purpose'] ?? '').toString().toLowerCase().trim();
                    return p == _selectedPurpose!.toLowerCase().trim();
                  }).toList();
                }

                if (_selectedPropertyType != null && _selectedPropertyType!.isNotEmpty && _selectedPropertyType!.toLowerCase() != 'all types') {
                  list = list.where((item) {
                    final t = (item['property_type'] ?? '').toString().toLowerCase().trim();
                    final st = (item['sub_property_type'] ?? '').toString().toLowerCase().trim();
                    final target = _selectedPropertyType!.toLowerCase().trim();
                    return t.contains(target) || st.contains(target);
                  }).toList();
                }

                if (_selectedBeds != null && _selectedBeds!.isNotEmpty && _selectedBeds!.toLowerCase() != 'any') {
                  final cleanBedStr = _selectedBeds!.replaceAll(RegExp(r'[^0-9]'), '');
                  final bedCount = int.tryParse(cleanBedStr);
                  if (bedCount != null && bedCount > 0) {
                    list = list.where((item) {
                      final itemBeds = int.tryParse((item['bedrooms'] ?? 0).toString()) ?? 0;
                      return itemBeds >= bedCount;
                    }).toList();
                  }
                }

                if (_selectedBaths != null && _selectedBaths!.isNotEmpty && _selectedBaths!.toLowerCase() != 'any') {
                  final cleanBathStr = _selectedBaths!.replaceAll(RegExp(r'[^0-9]'), '');
                  final bathCount = int.tryParse(cleanBathStr);
                  if (bathCount != null && bathCount > 0) {
                    list = list.where((item) {
                      final itemBaths = int.tryParse((item['bathrooms'] ?? 0).toString()) ?? 0;
                      return itemBaths >= bathCount;
                    }).toList();
                  }
                }

                if (_minPrice != null && _minPrice! > 0) {
                  list = list.where((item) {
                    final price = _parseNumericPrice(item['price']);
                    return price >= _minPrice!;
                  }).toList();
                }

                if (_maxPrice != null && _maxPrice! > 0) {
                  list = list.where((item) {
                    final price = _parseNumericPrice(item['price']);
                    return price <= _maxPrice!;
                  }).toList();
                }

                if (_minArea != null && _minArea! > 0) {
                  list = list.where((item) {
                    final area = double.tryParse((item['area_size'] ?? 0).toString()) ?? 0;
                    return area >= _minArea!;
                  }).toList();
                }

                if (_maxArea != null && _maxArea! > 0) {
                  list = list.where((item) {
                    final area = double.tryParse((item['area_size'] ?? 0).toString()) ?? 0;
                    return area <= _maxArea!;
                  }).toList();
                }

                if (_searchKeyword.isNotEmpty) {
                  final k = _searchKeyword.toLowerCase();
                  list = list.where((item) {
                    final t = (item['title'] ?? '').toString().toLowerCase();
                    final d = (item['description'] ?? '').toString().toLowerCase();
                    final c = (item['city'] ?? '').toString().toLowerCase();
                    return t.contains(k) || d.contains(k) || c.contains(k);
                  }).toList();
                }

                if (list.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 110),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return _buildPropertyCard(list[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dharttiGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.home_work_outlined, size: 48, color: dharttiGreen),
            ),
            SizedBox(height: 16),
            Text(
              "No Properties Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              "We couldn't find any listings matching your current filter criteria.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: Colors.white, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _clearAllFilters,
              label: Text("Show All Properties", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // REDESIGNED HEARTHLINE PROPERTY CARD
  // ==========================================
  // ==========================================
  // REDESIGNED LUXURY HEARTHLINE PROPERTY CARD
  // ==========================================
  Widget _buildPropertyCard(dynamic property) {
    final String imageUrl = (property['image_path'] ?? '').toString();
    final String whatsappNumber = (property['whatsappnumber'] ?? '').toString();
    final String phoneNumber = property['mobile_numbers'] != null && property['mobile_numbers'].toString().isNotEmpty
        ? property['mobile_numbers'].toString().replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').trim()
        : '';
    final String purpose = (property['purpose'] ?? 'Property').toString();
    final String subType = (property['sub_property_type'] ?? property['property_type'] ?? 'Property').toString();
    final String title = (property['title'] ?? 'Luxury Property').toString();
    final String city = (property['city'] ?? 'Location not specified').toString();
    final String priceDisplay = _formatPrice(property['price'], purpose);

    final int beds = int.tryParse((property['bedrooms'] ?? 0).toString()) ?? 0;
    final int baths = int.tryParse((property['bathrooms'] ?? 0).toString()) ?? 0;
    final String areaSize = (property['area_size'] ?? '').toString();
    final String areaUnit = (property['area_unit'] ?? 'Sq. Ft.').toString();
    final dynamic propId = property['id'];
    final bool isSaved = _favoritedIds.contains(propId);
    final bool hasInstallment = property['installment_available'] == true ||
        property['installment_available'] == 1 ||
        property['installment_available'] == '1';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(propertyId: propId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEBEFEB), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2E1D).withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Luxury Image Showcase with Dynamic Overlays
            Stack(
              children: [
                SizedBox(
                  height: 215,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 215,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),

                // Top Vignette Gradient for Legibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.42),
                          Colors.transparent,
                          Colors.black.withOpacity(0.60),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top Left Badges: Purpose Pill & Sub-Type Pill
                Positioned(
                  top: 14,
                  left: 14,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: dharttiGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "FOR ${purpose.toUpperCase()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Text(
                          subType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Right: Favorite Bookmark Button
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () async {
                      final isNowFav = await FavoriteService().togglePropertyFavorite(property);
                      setState(() {
                        if (isNowFav) {
                          _favoritedIds.add(propId);
                        } else {
                          _favoritedIds.remove(propId);
                        }
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isNowFav
                                  ? "Saved to favourites!"
                                  : "Removed from favourites",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: dharttiGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isSaved ? Colors.redAccent : Colors.black87,
                        size: 19,
                      ),
                    ),
                  ),
                ),

                // Bottom Left on Image: Easy Installment Tag
                if (hasInstallment)
                  Positioned(
                    bottom: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.credit_card_rounded, size: 12, color: dharttiGreen),
                          SizedBox(width: 4),
                          Text(
                            "Installments",
                            style: TextStyle(
                              color: dharttiGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Right on Image: Verified Tag
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF4ADE80)),
                        SizedBox(width: 4),
                        Text(
                          "Verified",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 2. Card Content & Specifications
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Price and Quick Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            priceDisplay,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: dharttiGreen,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subType,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 2: Property Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B231D),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Location Pin & City
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: dharttiGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 4: Specifications Pill Badges (Beds, Baths, Area Size)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (beds > 0) _buildSpecPill(Icons.bed_rounded, "$beds Beds"),
                      if (baths > 0) _buildSpecPill(Icons.bathtub_rounded, "$baths Baths"),
                      if (areaSize.isNotEmpty && areaSize != '0')
                        _buildSpecPill(Icons.square_foot_rounded, "$areaSize $areaUnit"),
                      if (beds == 0 && baths == 0 && (areaSize.isEmpty || areaSize == '0'))
                        _buildSpecPill(Icons.domain_rounded, subType),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Hairline Divider
                  Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
                  const SizedBox(height: 14),

                  // Row 5: Luxury Action Buttons (Call, WhatsApp, Share)
                  Row(
                    children: [
                      // Call Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _analyticsService.updateCallClicks(propId);
                              _makePhoneCall(phoneNumber);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: dharttiGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: dharttiGreen.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.call_rounded, color: Colors.white, size: 15),
                                  SizedBox(width: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Call",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // WhatsApp Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _analyticsService.updateWhatsAppClicks(propId);
                              _launchWhatsApp(whatsappNumber);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7EC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF25D366).withOpacity(0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.chat_bubble_rounded, color: Color(0xFF107C38), size: 14),
                                  SizedBox(width: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "WhatsApp",
                                      style: TextStyle(
                                        color: Color(0xFF107C38),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Share Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _shareProperty(
                            propertyId: propId,
                            title: title,
                            city: city,
                            price: priceDisplay,
                            imageUrl: imageUrl,
                            area: areaSize.isNotEmpty && areaSize != '0' ? '$areaSize $areaUnit' : null,
                            beds: beds > 0 ? '$beds' : null,
                            baths: baths > 0 ? '$baths' : null,
                            type: subType,
                            purpose: purpose,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE4E8E4)),
                            ),
                            child: Icon(Icons.share_outlined, size: 18, color: Colors.grey.shade700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 215,
      width: double.infinity,
      color: const Color(0xFFF1F5F2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_outlined, size: 44, color: dharttiGreen.withOpacity(0.4)),
          const SizedBox(height: 6),
          Text(
            "Dhartti Verified",
            style: TextStyle(
              color: dharttiGreen.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9E4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dharttiGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C352E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProperty({
    required dynamic propertyId,
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
      propertyId: propertyId,
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

  Widget _buildActiveChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dharttiGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dharttiGreen.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dharttiGreen,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          SizedBox(width: 5),
          GestureDetector(
            onTap: onDeleted,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dharttiGreen,
              ),
              child: Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPREHENSIVE FILTER BOTTOM SHEET
  // ==========================================
  void _openFilterBottomSheet() {
    String tempPurpose = _selectedPurpose ?? 'all';
    String tempCity = _selectedCity ?? 'All Cities';
    String tempType = _selectedPropertyType ?? 'All Types';
    String tempBeds = _selectedBeds ?? 'Any';
    String tempBaths = _selectedBaths ?? 'Any';
    double tempMaxPrice = _maxPrice ?? (tempPurpose == 'rent' ? 500000 : 50000000);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double sliderMax = tempPurpose == 'rent' ? 1000000 : 50000000;
            if (tempMaxPrice > sliderMax) tempMaxPrice = sliderMax;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Modal Handle & Header
                  Container(
                    padding: EdgeInsets.only(top: 12, bottom: 8, left: 20, right: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Filter Properties",
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempPurpose = 'all';
                                  tempCity = 'All Cities';
                                  tempType = 'All Types';
                                  tempBeds = 'Any';
                                  tempBaths = 'Any';
                                  tempMaxPrice = 50000000;
                                });
                              },
                              child: Text(
                                "Reset",
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                  // Filter Form Options
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      physics: BouncingScrollPhysics(),
                      children: [
                        // 1. Purpose Selector
                        _buildFilterSectionTitle("Purpose"),
                        Row(
                          children: [
                            _buildChoicePill("All", tempPurpose == 'all', () {
                              setSheetState(() => tempPurpose = 'all');
                            }),
                            SizedBox(width: 8),
                            _buildChoicePill("For Rent", tempPurpose == 'rent', () {
                              setSheetState(() {
                                tempPurpose = 'rent';
                                if (tempMaxPrice > 1000000) tempMaxPrice = 500000;
                              });
                            }),
                            SizedBox(width: 8),
                            _buildChoicePill("For Sale", tempPurpose == 'sell', () {
                              setSheetState(() => tempPurpose = 'sell');
                            }),
                          ],
                        ),
                        SizedBox(height: 20),

                        // 2. City Dropdown
                        _buildFilterSectionTitle("City"),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F9F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _cities.contains(tempCity) ? tempCity : _cities.first,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: _cities.map((city) {
                                return DropdownMenuItem<String>(
                                  value: city,
                                  child: Text(city, style: TextStyle(fontSize: 14, color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => tempCity = val);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // 3. Property Type Dropdown
                        _buildFilterSectionTitle("Property Type"),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F9F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _propertyTypes.contains(tempType) ? tempType : _propertyTypes.first,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: _propertyTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type, style: TextStyle(fontSize: 14, color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => tempType = val);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // 4. Bedrooms Selector
                        _buildFilterSectionTitle("Bedrooms"),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: ['Any', '1', '2', '3', '4', '5+'].map((bed) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildChoicePill(bed, tempBeds == bed, () {
                                  setSheetState(() => tempBeds = bed);
                                }),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20),

                        // 5. Bathrooms Selector
                        _buildFilterSectionTitle("Bathrooms"),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: ['Any', '1', '2', '3', '4', '5+'].map((bath) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildChoicePill(bath, tempBaths == bath, () {
                                  setSheetState(() => tempBaths = bath);
                                }),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20),

                        // 6. Max Price Slider & Presets
                        _buildFilterSectionTitle("Max Price: ${_formatPrice(tempMaxPrice, tempPurpose)}"),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: dharttiGreen,
                            inactiveTrackColor: Colors.grey.shade200,
                            thumbColor: dharttiGreen,
                            trackHeight: 4,
                          ),
                          child: Slider(
                            min: 0,
                            max: sliderMax,
                            value: tempMaxPrice > sliderMax ? sliderMax : tempMaxPrice,
                            onChanged: (val) {
                              setSheetState(() => tempMaxPrice = val);
                            },
                          ),
                        ),
                        // Quick Price Presets
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: (tempPurpose == 'rent'
                                ? [
                                    {'label': '< 30k', 'val': 30000.0},
                                    {'label': '< 50k', 'val': 50000.0},
                                    {'label': '< 1 Lakh', 'val': 100000.0},
                                    {'label': '< 2.5 Lakh', 'val': 250000.0},
                                    {'label': 'Any', 'val': 1000000.0},
                                  ]
                                : [
                                    {'label': '< 50 Lakh', 'val': 5000000.0},
                                    {'label': '< 1 Crore', 'val': 10000000.0},
                                    {'label': '< 2.5 Crore', 'val': 25000000.0},
                                    {'label': '< 5 Crore', 'val': 50000000.0},
                                    {'label': 'Any', 'val': 50000000.0},
                                  ]).map((preset) {
                              bool isSelected = (tempMaxPrice == preset['val']);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  backgroundColor: isSelected ? dharttiGreen : Color(0xFFF2F4F2),
                                  label: Text(
                                    preset['label'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    setSheetState(() {
                                      tempMaxPrice = preset['val'] as double;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: dharttiGreen, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.bookmark_add_outlined, color: dharttiGreen, size: 17),
                              label: const Text(
                                "Save",
                                style: TextStyle(color: dharttiGreen, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                setState(() {
                                  _selectedPurpose = tempPurpose == 'all' ? null : tempPurpose;
                                  _selectedCity = tempCity == 'All Cities' ? null : tempCity;
                                  _selectedPropertyType = tempType == 'All Types' ? null : tempType;
                                  _selectedBeds = tempBeds == 'Any' ? null : tempBeds;
                                  _selectedBaths = tempBaths == 'Any' ? null : tempBaths;
                                  if (tempPurpose == 'rent') {
                                    _maxPrice = tempMaxPrice < 1000000 ? tempMaxPrice : null;
                                  } else {
                                    _maxPrice = tempMaxPrice < 50000000 ? tempMaxPrice : null;
                                  }
                                  _fetchProperties();
                                });
                                _showSaveSearchModal();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dharttiGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                setState(() {
                                  _selectedPurpose = tempPurpose == 'all' ? null : tempPurpose;
                                  _selectedCity = tempCity == 'All Cities' ? null : tempCity;
                                  _selectedPropertyType = tempType == 'All Types' ? null : tempType;
                                  _selectedBeds = tempBeds == 'Any' ? null : tempBeds;
                                  _selectedBaths = tempBaths == 'Any' ? null : tempBaths;
                                  if (tempPurpose == 'rent') {
                                    _maxPrice = tempMaxPrice < 1000000 ? tempMaxPrice : null;
                                  } else {
                                    _maxPrice = tempMaxPrice < 50000000 ? tempMaxPrice : null;
                                  }
                                  _fetchProperties();
                                });
                              },
                              child: const Text(
                                "Apply Filters",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildChoicePill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? dharttiGreen : Color(0xFFF2F4F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? dharttiGreen : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
