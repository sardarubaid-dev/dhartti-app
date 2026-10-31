import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/constants.dart';
import 'package:dhartti/Model/area_guide_propertyModel.dart';
import 'package:dhartti/service/area_guideService.dart';
import 'package:dhartti/area_guide_detail_screen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';

class AreaGuideScreen extends StatefulWidget {
  const AreaGuideScreen({Key? key}) : super(key: key);

  @override
  State<AreaGuideScreen> createState() => _AreaGuideScreenState();
}

class _AreaGuideScreenState extends State<AreaGuideScreen> {
  final AreaGuideService _service = AreaGuideService(
    baseUrl: AppConstants.baseUrl,
    imageUrl: AppConstants.baseUrl.replaceAll('/api', ''),
  );

  late Future<Map<String, dynamic>> _areaGuideData;
  String _selectedCity = 'all';
  String _selectedPurpose = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Preset famous societies in Pakistan with descriptions
  final List<Map<String, dynamic>> _famousSocieties = [
    {
      'name': 'DHA Defence',
      'city': 'Lahore',
      'tagline': 'Pakistan’s gold standard in security & luxury living',
      'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
      'properties': 148,
    },
    {
      'name': 'Bahria Town',
      'city': 'Rawalpindi / Islamabad',
      'tagline': 'Master-planned lifestyle with international attractions',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      'properties': 120,
    },
    {
      'name': 'Gulberg Greens',
      'city': 'Islamabad',
      'tagline': 'Elite farmhouses & upscale corporate commercial corridors',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
      'properties': 86,
    },
    {
      'name': 'Clifton & Defence',
      'city': 'Karachi',
      'tagline': 'Coastal high-rises and premier commercial business centers',
      'image': 'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=800&q=80',
      'properties': 94,
    },
    {
      'name': 'Capital Smart City',
      'city': 'Islamabad',
      'tagline': 'First smart eco-city with automated utilities and BRT',
      'image': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&q=80',
      'properties': 58,
    },
    {
      'name': 'Lake City',
      'city': 'Lahore',
      'tagline': 'Serene golf resort community with ring road access',
      'image': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
      'properties': 42,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _areaGuideData = _service.getAreaGuideData();
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

  String _resolveImage(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&q=80';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final serverBase = AppConstants.baseUrl.replaceAll('/api', '');
    return '$serverBase/${path.startsWith('/') ? path.substring(1) : path}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF108224);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Area & Society Guides',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _areaGuideData,
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
                      'Failed to load area guides',
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
          final rawPurposes = (data['purposes'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final properties = (data['properties'] as List<PropertyAreaGuide>?) ?? [];

          // Dynamic server locations if available
          final serverLocations = (data['locations'] as List?) ?? [];
          final displayedSocieties = serverLocations.isNotEmpty
              ? serverLocations.map((l) {
                  return {
                    'name': (l['name'] ?? 'Society').toString(),
                    'city': 'Pakistan',
                    'tagline': 'Vibrant community with prime amenities & infrastructure',
                    'image': l['image'] != null ? _resolveImage(l['image']) : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80',
                    'properties': l['properties_count'] ?? 10,
                  };
                }).toList()
              : _famousSocieties;

          // Filter properties
          final filteredProperties = properties.where((p) {
            final city = (p.city ?? '').toLowerCase();
            final purpose = (p.purpose ?? '').toLowerCase();
            final title = (p.title ?? '').toLowerCase();

            final matchesCity = _selectedCity == 'all' || city == _selectedCity.toLowerCase();
            final matchesPurpose = _selectedPurpose == 'all' ||
                (_selectedPurpose == 'sell' && (purpose.contains('sale') || purpose.contains('sell'))) ||
                (_selectedPurpose == 'rent' && purpose.contains('rent'));
            final matchesSearch = _searchQuery.isEmpty || title.contains(_searchQuery) || city.contains(_searchQuery);

            return matchesCity && matchesPurpose && matchesSearch;
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
                      // --- Hero Banner & Society Search Card ---
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.explore_outlined, color: primaryColor, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Explore Societies in Pakistan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Discover everyday life, security, and amenities in top housing societies',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // City & Purpose Dropdowns
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
                                final purposeDropdown = _buildFilterDropdown(
                                  label: 'Purpose',
                                  value: _selectedPurpose,
                                  items: ['all', ...rawPurposes],
                                  icon: Icons.category_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedPurpose = val);
                                  },
                                );

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      cityDropdown,
                                      const SizedBox(height: 10),
                                      purposeDropdown,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: cityDropdown),
                                    const SizedBox(width: 12),
                                    Expanded(child: purposeDropdown),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Search Keyword input
                            TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Search society or location (e.g. DHA, Bahria, Gulberg)...',
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

                      // --- Top Housing Societies Guides ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apartment_rounded, size: 20, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Popular Housing Societies',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'Area Guides',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 650;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 2 : 1,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 170,
                            ),
                            itemCount: displayedSocieties.length,
                            itemBuilder: (context, idx) {
                              final soc = displayedSocieties[idx];
                              return _buildSocietyGuideCard(soc, primaryColor);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // --- Recommended Properties in these Areas ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Properties in These Societies (${filteredProperties.length})',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedCity != 'all' || _selectedPurpose != 'all' || _searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCity = 'all';
                                  _selectedPurpose = 'all';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              child: Text(
                                'Reset',
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
                                'No listings found in this society/city',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your search query or selecting another city.',
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

  Widget _buildSocietyGuideCard(Map<String, dynamic> soc, Color primaryColor) {
    final name = (soc['name'] ?? 'Housing Society').toString();
    final city = (soc['city'] ?? 'Pakistan').toString();
    final tagline = (soc['tagline'] ?? '').toString();
    final image = (soc['image'] ?? '').toString();
    final propCount = (soc['properties'] ?? 0) as int;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AreaGuideDetailScreen(
              societyName: name,
              cityName: city,
              imageUrl: image,
              propertiesCount: propCount,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.apartment, size: 36, color: primaryColor),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 2),
                        Text(
                          city,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tagline,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'View Guide',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyAreaGuide prop, Color primaryColor) {
    return InkWell(
      onTap: () {
        if (prop.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailPage(propertyId: prop.id!),
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
                    _resolveImage(prop.imagePath),
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
                        (prop.purpose ?? 'FOR SALE').toUpperCase(),
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
                    _formatPrice(prop.price ?? 0),
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prop.title ?? 'Listing',
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
                          prop.city ?? 'Pakistan',
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
                      if ((prop.bedrooms ?? 0) > 0)
                        Row(
                          children: [
                            const Icon(Icons.bed_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 3),
                            Text('${prop.bedrooms} Beds', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      if ((prop.bathrooms ?? 0) > 0)
                        Row(
                          children: [
                            const Icon(Icons.bathtub_outlined, size: 14, color: Colors.black54),
                            const SizedBox(width: 3),
                            Text('${prop.bathrooms} Baths', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      if (prop.areaSize != null)
                        Text(
                          '${prop.areaSize} ${prop.areaUnit ?? ''}',
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
