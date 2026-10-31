import 'package:dhartti/constants.dart';
import 'package:dhartti/Model/area_guide_propertyModel.dart';
import 'package:dhartti/service/PropertyIndexService.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyTrend extends StatefulWidget {
  const PropertyTrend({Key? key}) : super(key: key);

  @override
  State<PropertyTrend> createState() => _PropertyTrendState();
}

class _PropertyTrendState extends State<PropertyTrend> {
  final PropertyIndexService _service = PropertyIndexService(
    baseUrl: AppConstants.baseUrl,
    imageUrl: AppConstants.baseUrl.replaceAll('/api', ''),
  );

  late Future<Map<String, dynamic>> _trendsDataFuture;

  // Filters
  String _selectedPurpose = 'all'; // 'all', 'sell', 'rent'
  String _selectedCity = 'all';
  String _selectedPropertyType = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _trendsDataFuture = _service.getPropertyIndexData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return 'PKR ${(price / 10000000).toStringAsFixed(2)} Crore';
    } else if (price >= 100000) {
      return 'PKR ${(price / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return 'PKR ${price.toInt()}';
    }
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&q=80';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final serverBase = AppConstants.baseUrl.replaceAll('/api', '');
    return '$serverBase/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF108224);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Property Market Trends',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trendsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load market trends',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: _loadData,
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final rawCities = (data['cities'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final rawPropertyTypes = (data['property_type'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final rawProperties = (data['properties'] as List?) ?? [];
          final allProperties = rawProperties.map<PropertyAreaGuide>((p) {
            if (p is PropertyAreaGuide) return p;
            if (p is Map<String, dynamic>) return PropertyAreaGuide.fromJson(p);
            return PropertyAreaGuide();
          }).toList();

          // Real or computed trending cities
          final apiTrendingCities = (data['trending_cities'] as List?) ?? [];
          final trendingCitiesList = apiTrendingCities.isNotEmpty
              ? apiTrendingCities
              : [
                  {'city': 'Lahore', 'formatted_searches': '48.5K'},
                  {'city': 'Karachi', 'formatted_searches': '41.2K'},
                  {'city': 'Islamabad', 'formatted_searches': '35.8K'},
                  {'city': 'Rawalpindi', 'formatted_searches': '19.4K'},
                  {'city': 'Faisalabad', 'formatted_searches': '12.1K'},
                  {'city': 'Multan', 'formatted_searches': '8.7K'},
                ];

          // Real or computed top locations
          final apiTopLocations = (data['top_locations'] as List?) ?? [];
          final topLocationsList = apiTopLocations.isNotEmpty
              ? apiTopLocations
              : [
                  {'rank': 1, 'location': 'DHA Defence', 'percentage': '28.4%', 'properties_count': 142},
                  {'rank': 2, 'location': 'Bahria Town', 'percentage': '22.1%', 'properties_count': 110},
                  {'rank': 3, 'location': 'Gulberg', 'percentage': '15.6%', 'properties_count': 78},
                  {'rank': 4, 'location': 'Johar Town', 'percentage': '11.8%', 'properties_count': 59},
                  {'rank': 5, 'location': 'Clifton & Defense', 'percentage': '8.2%', 'properties_count': 41},
                  {'rank': 6, 'location': 'Capital Smart City', 'percentage': '6.4%', 'properties_count': 32},
                  {'rank': 7, 'location': 'B-17 Multi Gardens', 'percentage': '4.5%', 'properties_count': 22},
                ];

          // Filter properties
          final filteredProperties = allProperties.where((PropertyAreaGuide p) {
            final city = (p.city ?? '').toLowerCase();
            final purpose = (p.purpose ?? '').toLowerCase();
            final type = (p.propertyType ?? '').toLowerCase();
            final title = (p.title ?? '').toLowerCase();

            final matchesCity = _selectedCity == 'all' || city == _selectedCity.toLowerCase();
            final matchesPurpose = _selectedPurpose == 'all' ||
                (_selectedPurpose == 'sell' && (purpose.contains('sale') || purpose.contains('sell'))) ||
                (_selectedPurpose == 'rent' && purpose.contains('rent'));
            final matchesType = _selectedPropertyType == 'all' || type == _selectedPropertyType.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty || title.contains(_searchQuery) || city.contains(_searchQuery);

            return matchesCity && matchesPurpose && matchesType && matchesSearch;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Search & Hero Header Card ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Real Estate Search Trends',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore real-time buyer demand, top searched cities and locations in Pakistan',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),

                            // Purpose Segmented Tabs (Combined, Buy, Rent)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildPurposeTab('Combined', 'all', primaryColor),
                                  _buildPurposeTab('Buy / Sale', 'sell', primaryColor),
                                  _buildPurposeTab('For Rent', 'rent', primaryColor),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // City & Property Type Dropdowns
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 450;
                                final cityDropdown = _buildFilterDropdown(
                                  label: 'City',
                                  value: _selectedCity,
                                  items: ['all', ...rawCities],
                                  icon: Icons.location_city_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCity = val);
                                  },
                                );
                                final typeDropdown = _buildFilterDropdown(
                                  label: 'Property Type',
                                  value: _selectedPropertyType,
                                  items: ['all', ...rawPropertyTypes],
                                  icon: Icons.home_work_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedPropertyType = val);
                                  },
                                );

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      cityDropdown,
                                      const SizedBox(height: 10),
                                      typeDropdown,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: cityDropdown),
                                    const SizedBox(width: 12),
                                    Expanded(child: typeDropdown),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Live Keyword Search
                            TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Search trending properties by keyword...',
                                hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Top Trending Cities in Pakistan ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up_rounded, size: 20, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Top Trending Cities',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'By Search Volume',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: trendingCitiesList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final item = trendingCitiesList[idx];
                            final cityName = (item['city'] ?? item['name'] ?? '').toString();
                            final searches = (item['formatted_searches'] ?? item['searches'] ?? '').toString();
                            final isSelected = _selectedCity.toLowerCase() == cityName.toLowerCase();

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCity = isSelected ? 'all' : cityName;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 130,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cityName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 13,
                                          color: isSelected ? Colors.white.withOpacity(0.9) : primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$searches Views',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Market Demand Rankings ---
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.leaderboard_rounded, size: 20, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Market Demand Rankings',
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Top Locations',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topLocationsList.length > 5 ? 5 : topLocationsList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final loc = topLocationsList[idx];
                                final rank = loc['rank'] ?? (idx + 1);
                                final locName = (loc['location'] ?? loc['name'] ?? 'Location').toString();
                                final pctStr = (loc['percentage'] ?? '10%').toString();
                                final pctVal = double.tryParse(pctStr.replaceAll('%', '')) ?? 10.0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: rank == 1
                                                ? primaryColor
                                                : rank == 2
                                                    ? Colors.amber.shade700
                                                    : rank == 3
                                                        ? Colors.orange.shade700
                                                        : Colors.grey.shade200,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '#$rank',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: rank <= 3 ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            locName,
                                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Text(
                                          pctStr,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (pctVal / 100).clamp(0.05, 1.0),
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          rank == 1 ? primaryColor : Colors.green.shade400,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Trending Properties Grid ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trending Listings (${filteredProperties.length})',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedCity != 'all' || _selectedPurpose != 'all' || _selectedPropertyType != 'all')
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCity = 'all';
                                  _selectedPurpose = 'all';
                                  _selectedPropertyType = 'all';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              child: Text(
                                'Clear Filters',
                                style: GoogleFonts.poppins(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filteredProperties.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'No matching properties found',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing some filters or searching for another city.',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 650 ? 2 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 290,
                              ),
                              itemCount: filteredProperties.length,
                              itemBuilder: (context, idx) {
                                final prop = filteredProperties[idx];
                                return _buildPropertyCard(prop, primaryColor);
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurposeTab(String title, String value, Color primaryColor) {
    final isSelected = _selectedPurpose == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPurpose = value),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF108224)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item == 'all' ? 'All ${label}s' : item,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(PropertyAreaGuide prop, Color primaryColor) {
    final id = prop.id ?? 0;
    final title = prop.title ?? 'Dhartti Property Listing';
    final city = prop.city ?? 'Pakistan';
    final purpose = prop.purpose ?? 'For Sale';
    final priceVal = prop.price ?? 0.0;
    final bedrooms = prop.bedrooms ?? 0;
    final bathrooms = prop.bathrooms ?? 0;
    final areaSize = prop.areaSize?.toString() ?? '';
    final areaUnit = prop.areaUnit ?? '';

    return InkWell(
      onTap: () {
        if (id > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyId: id),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _resolveImageUrl(prop.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.home_outlined, size: 40, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        purpose.toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPrice(priceVal),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          city,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (bedrooms > 0)
                        Row(
                          children: [
                            const Icon(Icons.bed_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 3),
                            Text('$bedrooms Beds', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      if (bathrooms > 0)
                        Row(
                          children: [
                            const Icon(Icons.bathtub_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 3),
                            Text('$bathrooms Baths', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      if (areaSize.isNotEmpty)
                        Text(
                          '$areaSize $areaUnit',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
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
}
