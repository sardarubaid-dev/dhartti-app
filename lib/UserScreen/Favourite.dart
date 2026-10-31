import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Auth_Screens/register.dart';
import 'package:dhartti/service/favorite_service.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';

class FavouriteScreen extends StatefulWidget {
  final int initialTabIndex;
  const FavouriteScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> with SingleTickerProviderStateMixin {
  final FavoriteService _favService = FavoriteService();
  late TabController _tabController;

  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoading = true;
  bool _isGuest = false;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isGuest = false;
      _isLoading = true;
    });

    final favs = await _favService.getFavoriteProperties();
    final searches = await _favService.getSavedSearches();
    if (mounted) {
      setState(() {
        _favorites = favs;
        _savedSearches = searches;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFav(Map<String, dynamic> item) async {
    final removedItem = Map<String, dynamic>.from(item);
    final propId = item['id'];
    await _favService.removeFavoriteProperty(propId);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Removed from favourites',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: dharttiGreen,
            onPressed: () async {
              await _favService.togglePropertyFavorite(removedItem);
              _loadData();
            },
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _removeSearch(String id, String title) async {
    await _favService.removeSavedSearch(id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Search "$title" removed',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return 'PKR Price on Call';
    final double? price = double.tryParse(rawPrice.toString().replaceAll(',', '').replaceAll('PKR', '').trim());
    if (price == null || price <= 0) return 'PKR Price on Call';

    if (price >= 10000000) {
      final crore = price / 10000000;
      return 'PKR ${crore.toStringAsFixed(crore.truncateToDouble() == crore ? 0 : 2)} Crore';
    } else if (price >= 100000) {
      final lac = price / 100000;
      return 'PKR ${lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2)} Lakh';
    }
    return 'PKR ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          children: [
            Text(
              'Saved & Favourites',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: textDark,
              ),
            ),
            Text(
              'Shortlisted properties & queries',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: dharttiGreen, size: 20),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: dharttiGreen,
                  boxShadow: [
                    BoxShadow(
                      color: dharttiGreen.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: textMuted,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12.5),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_rounded, size: 15),
                        const SizedBox(width: 6),
                        Text('Properties (${_favorites.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_rounded, size: 15),
                        const SizedBox(width: 6),
                        Text('Searches (${_savedSearches.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isGuest
          ? _buildGuestState()
          : (_isLoading
              ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFavoritesList(),
                    _buildSavedSearchesList(),
                  ],
                )),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 42,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In Required',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log into your Dhartti account to view your shortlisted properties and saved searches.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sign In to Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ).then((_) => _loadData());
              },
              child: Text(
                'Don’t have an account? Register',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    if (_favorites.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 36, color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Favourites Saved Yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart icon on any property listing while browsing to save it here for fast comparisons.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen(initialIndex: 1)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 2,
                  shadowColor: dharttiGreen.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Browse Properties Now',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: dharttiGreen,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: _favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = _favorites[index];
              final imgUrl = PropertyService.formatPropertyImageUrl(item['image_path']);
              final propId = int.tryParse(item['id']?.toString() ?? '0');
              final purpose = (item['purpose'] ?? 'Sell').toString().toUpperCase();
              final isRent = purpose.contains('RENT');
              final beds = item['bedrooms']?.toString();
              final baths = item['bathrooms']?.toString();
              final area = item['area_size']?.toString();
              final areaUnit = item['area_unit']?.toString() ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (propId != null && propId > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyId: propId)),
                        ).then((_) => _loadData());
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail with Purpose Badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 108,
                                  height: 108,
                                  color: const Color(0xFFF1F5F9),
                                  child: imgUrl.isNotEmpty
                                      ? Image.network(
                                          imgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                                        )
                                      : _buildPlaceholderIcon(),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isRent ? const Color(0xFF0284C7) : dharttiGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isRent ? 'RENT' : 'BUY',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Details Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatPrice(item['price']),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: dharttiGreen,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _removeFav(item),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['title'] ?? 'Prime Property Listing',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        '${item['location'] ?? ''}, ${item['city'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(fontSize: 11.5, color: textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Feature Badges (Area, Beds, Baths)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (area != null && area.isNotEmpty)
                                      _buildFeatureBadge(Icons.square_foot_rounded, '$area $areaUnit'),
                                    if (beds != null && beds.isNotEmpty && beds != '0')
                                      _buildFeatureBadge(Icons.bed_rounded, '$beds Beds'),
                                    if (baths != null && baths.isNotEmpty && baths != '0')
                                      _buildFeatureBadge(Icons.bathtub_outlined, '$baths Baths'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSavedSearchesList() {
    if (_savedSearches.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: dharttiGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: dharttiGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_outline_rounded, size: 36, color: dharttiGreen),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Saved Searches Yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Whenever you filter properties by city, price or type, tap "Save Search" to keep your custom query ready at a single tap.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: textMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: dharttiGreen.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
                label: Text(
                  "Filter & Search Listings",
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen(initialIndex: 1)),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: _savedSearches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final s = _savedSearches[index];
            final title = s['title'] ?? 'Custom Search';
            final city = s['city'] ?? 'All Cities';
            final type = s['property_type'] ?? 'All Types';
            final purpose = s['purpose'] ?? 'All';
            final beds = s['beds'];
            final baths = s['baths'];
            final maxPrice = s['max_price'];
            final minPrice = s['min_price'];
            final keyword = s['keyword'];
            final createdAt = (s['created_at'] ?? '').toString().split('T').first;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BottomNavBarScreen(
                          initialIndex: 1,
                          initialCity: city == 'All Cities' ? null : city,
                          initialPurpose: purpose == 'All' ? null : purpose,
                          initialPropertyType: type == 'All Types' ? null : type,
                          initialBeds: beds == 'Any' ? null : beds,
                          initialBaths: baths == 'Any' ? null : baths,
                          initialMinPrice: minPrice != null ? (minPrice as num).toDouble() : null,
                          initialMaxPrice: maxPrice != null ? (maxPrice as num).toDouble() : null,
                          initialMinArea: s['min_area'] != null ? (s['min_area'] as num).toDouble() : null,
                          initialMaxArea: s['max_area'] != null ? (s['max_area'] as num).toDouble() : null,
                          initialKeyword: keyword,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Title + Date + Delete
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dharttiGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.saved_search_rounded, color: dharttiGreen, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textDark,
                                    ),
                                  ),
                                  if (createdAt.isNotEmpty)
                                    Text(
                                      'Saved $createdAt',
                                      style: GoogleFonts.poppins(fontSize: 11, color: textMuted),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 19),
                              visualDensity: VisualDensity.compact,
                              tooltip: "Delete Search",
                              onPressed: () => _removeSearch(s['id']?.toString() ?? '', title),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Criteria Filter Tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (purpose != 'All' && purpose != 'all')
                              _buildSearchTag("For ${purpose.toString().toUpperCase()}", dharttiGreen),
                            if (city != 'All Cities')
                              _buildSearchTag("City: $city", const Color(0xFF0284C7)),
                            if (type != 'All Types')
                              _buildSearchTag("Type: $type", const Color(0xFF7C3AED)),
                            if (beds != null && beds != 'Any')
                              _buildSearchTag("$beds Beds", const Color(0xFF475569)),
                            if (baths != null && baths != 'Any')
                              _buildSearchTag("$baths Baths", const Color(0xFF475569)),
                            if (maxPrice != null && (maxPrice as num) > 0)
                              _buildSearchTag("Max: ${_formatPrice(maxPrice)}", const Color(0xFFD97706)),
                            if (keyword != null && keyword.toString().isNotEmpty)
                              _buildSearchTag('"$keyword"', dharttiGreen),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 8),

                        // Bottom Action CTA (Fully Responsive)
                        Row(
                          children: [
                            const Icon(Icons.touch_app_outlined, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Tap to view matching properties',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 11.5, color: textMuted),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: dharttiGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(Icons.home_work_rounded, color: Colors.grey, size: 36),
    );
  }
}
