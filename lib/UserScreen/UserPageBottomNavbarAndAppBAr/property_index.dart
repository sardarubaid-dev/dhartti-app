import 'package:dhartti/constants.dart';
import 'package:flutter/material.dart';
import 'package:dhartti/Model/area_guide_propertyModel.dart';
import 'package:dhartti/service/PropertyIndexService.dart';
import 'package:dhartti/Model/property_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class PropertyIndex extends StatefulWidget {
  const PropertyIndex({Key? key}) : super(key: key);

  @override
  State<PropertyIndex> createState() => _PropertyIndexState();
}

class _PropertyIndexState extends State<PropertyIndex> {
  final PropertyIndexService _service = PropertyIndexService(
    baseUrl: AppConstants.baseUrl,
    imageUrl: "http://192.168.100.74/Dhartti%20Website/dhartti/public",
  );

  late Future<Map<String, dynamic>> _areaGuideData;
  String? _selectedCity = 'all';
  String? _selectedPurpose = 'all';
  String? _selectedPropertyType = 'all';
  String? _selectedAreaSize = 'all';
  bool _isSearching = false;
  late List<PropertyAreaGuide> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'PKR');

  @override
  void initState() {
    super.initState();
    _areaGuideData = _service.getPropertyIndexData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf5f5f5),
              Color(0xFFe8f5e9),
            ],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _areaGuideData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (!snapshot.hasData) {
              return _buildEmptyState();
            }

            final cities = snapshot.data!['cities'] as List<String>;
            final purposes = snapshot.data!['purposes'] as List<String>;
            final propertyTypes = snapshot.data!['property_type'] as List<String>;
            final areaSizes = snapshot.data!['area_size'] as List<String>;

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(isLargeScreen),
                _buildHeroBanner(cities, purposes, propertyTypes, areaSizes, isLargeScreen),
                _isSearching
                    ? _buildSearchResultsSection(isLargeScreen, isMediumScreen)
                    : _buildAllPropertiesSection(snapshot.data!['properties'], isLargeScreen, isMediumScreen),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  SliverAppBar _buildAppBar(bool isLargeScreen) {
    return SliverAppBar(
      backgroundColor: _scrollOffset > 100 ? Colors.white : Colors.green,
      elevation: _scrollOffset > 100 ? 4 : 0,
      pinned: true,
      floating: true,
      expandedHeight: isLargeScreen ? 80 : 100,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green[800]!.withOpacity(0.9),
                Colors.green[600]!.withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: AnimatedOpacity(
          opacity: _scrollOffset > 100 ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Find Your Dream Property',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen ? 24 : 20,
                shadows: [
            Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
    ),
    actions: [
    IconButton(
    icon: Icon(Icons.search, color: _scrollOffset > 100 ? Colors.green : Colors.white),
    onPressed: () {
    FocusScope.of(context).requestFocus(FocusNode());
    _scrollController.animateTo(
    380,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    );
    },
    ),
    IconButton(
    icon: Icon(Icons.notifications_none, color: _scrollOffset > 100 ? Colors.grey[800] : Colors.white),
    onPressed: () {},
    ),
    IconButton(
    icon: Icon(Icons.favorite_border, color: _scrollOffset > 100 ? Colors.grey[800] : Colors.white),
    onPressed: () {},
    ),
    if (isLargeScreen)
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Center(
    child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    child: const Text(
    'Sign In',
    style: TextStyle(color: Colors.green),
    ),
    ),
    ),
    ),
    ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Properties...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/error.svg',
            height: 120,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _areaGuideData = _service.getPropertyIndexData();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/empty.svg',
            height: 120,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 20),
          Text(
            'No Properties Found',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We couldn\'t find any properties matching your criteria',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedCity = 'all';
                _selectedPurpose = 'all';
                _selectedPropertyType = 'all';
                _selectedAreaSize = 'all';
                _isSearching = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Reset Filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeroBanner(List<String> cities, List<String> purposes,
      List<String> propertyTypes, List<String> areaSizes, bool isLargeScreen) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
      Container(
      height: isLargeScreen ? 500 : 400,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/property-banner.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
      ),
      Container(
        height: isLargeScreen ? 500 : 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[800]!.withOpacity(0.4),
              Colors.green[600]!.withOpacity(0.3),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 40 : 20,
            vertical: isLargeScreen ? 40 : 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            'Find Your Perfect Home',
            style: TextStyle(
                color: Colors.white,
                fontSize: isLargeScreen ? 42 : 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
                shadows: [
            Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover the best properties in your desired location',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isLargeScreen ? 20 : 16,
            shadows: [
              Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildSearchCard(cities, purposes, propertyTypes, areaSizes, isLargeScreen),
        ],
      ),
    ),
    ),
    ],
    ),
    );
  }

  Widget _buildSearchCard(List<String> cities, List<String> purposes,
      List<String> propertyTypes, List<String> areaSizes, bool isLargeScreen) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by location, property...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 24),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _buildFilterDropdown(
                  value: _selectedCity,
                  items: ['all', ...cities],
                  icon: Icons.location_city,
                  hint: 'City',
                  isLargeScreen: isLargeScreen,
                ),
                _buildFilterDropdown(
                  value: _selectedPurpose,
                  items: ['all', ...purposes],
                  icon: Icons.category,
                  hint: 'Purpose',
                  isLargeScreen: isLargeScreen,
                ),
                _buildFilterDropdown(
                  value: _selectedPropertyType,
                  items: ['all', ...propertyTypes],
                  icon: Icons.home_work,
                  hint: 'Type',
                  isLargeScreen: isLargeScreen,
                ),
                _buildFilterDropdown(
                  value: _selectedAreaSize,
                  items: ['all', ...areaSizes],
                  icon: Icons.aspect_ratio,
                  hint: 'Size',
                  isLargeScreen: isLargeScreen,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 5,
                ),
                child: Text(
                  'Search Properties',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required bool isLargeScreen,
  }) {
    return Container(
      width: isLargeScreen ? 200 : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 20 : 15,
            vertical: isLargeScreen ? 18 : 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, size: 20, color: Colors.green),
          hintText: hint,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item == 'all' ? 'All $hint' : item,
              style: TextStyle(fontSize: isLargeScreen ? 15 : 13),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (hint == 'City') _selectedCity = value;
            if (hint == 'Purpose') _selectedPurpose = value;
            if (hint == 'Type') _selectedPropertyType = value;
            if (hint == 'Size') _selectedAreaSize = value;
          });
        },
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.green),
        borderRadius: BorderRadius.circular(12),
        isExpanded: true,
      ),
    );
  }

  void _handleSearch() async {
    if (_searchController.text.isEmpty &&
        _selectedCity == 'all' &&
        _selectedPurpose == 'all' &&
        _selectedPropertyType == 'all' &&
        _selectedAreaSize == 'all') {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('Please enter search criteria'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _service.searchProperties(
        city: _selectedCity,
        purpose: _selectedPurpose,
        propertyType: _selectedPropertyType,
        areaSize: _selectedAreaSize,
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  SliverPadding _buildAllPropertiesSection(
      List<PropertyAreaGuide> properties, bool isLargeScreen, bool isMediumScreen) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isLargeScreen ? 40 : 20,
        isLargeScreen ? 40 : 20,
        isLargeScreen ? 40 : 20,
        40,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLargeScreen
              ? 3
              : isMediumScreen
              ? 2
              : 1,
          crossAxisSpacing: isLargeScreen ? 30 : 20,
          mainAxisSpacing: isLargeScreen ? 30 : 20,
          childAspectRatio: isLargeScreen ? 0.85 : 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return _buildPropertyCard(properties[index], isLargeScreen);
          },
          childCount: properties.length,
        ),
      ),
    );
  }

  SliverPadding _buildSearchResultsSection(bool isLargeScreen, bool isMediumScreen) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isLargeScreen ? 40 : 20,
        isLargeScreen ? 40 : 20,
        isLargeScreen ? 40 : 20,
        40,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLargeScreen
              ? 3
              : isMediumScreen
              ? 2
              : 1,
          crossAxisSpacing: isLargeScreen ? 30 : 20,
          mainAxisSpacing: isLargeScreen ? 30 : 20,
          childAspectRatio: isLargeScreen ? 0.85 : 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            return _buildPropertyCard(_searchResults[index], isLargeScreen);
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PropertyAreaGuide property, bool isLargeScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to property details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      property.imagePath ?? 'https://source.unsplash.com/random/800x600/?house,property',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 22,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    property.city ?? 'Unknown',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLargeScreen ? 15 : 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPurposeColor(property.purpose ?? ''),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              property.purpose ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLargeScreen ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Property Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 20 : 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title ?? 'No Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isLargeScreen ? 20 : 16,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(120 reviews)',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureIcon(
                          icon: Icons.king_bed,
                          value: '${property.bedrooms ?? 0} Beds',
                          isLargeScreen: isLargeScreen,
                        ),
                        _buildFeatureIcon(
                          icon: Icons.bathtub,
                          value: '${property.bathrooms ?? 0} Baths',
                          isLargeScreen: isLargeScreen,
                        ),
                        _buildFeatureIcon(
                          icon: Icons.zoom_out_map,
                          value: '${property.areaSize ?? 'N/A'} sqft',
                          isLargeScreen: isLargeScreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currencyFormat.format(property.price ?? 0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isLargeScreen ? 22 : 18,
                            color: Colors.green[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            property.propertyType ?? '',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontSize: isLargeScreen ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

  Widget _buildFeatureIcon({
    required IconData icon,
    required String value,
    required bool isLargeScreen,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isLargeScreen ? 20 : 16, color: Colors.green),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isLargeScreen ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPurposeColor(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'rent':
        return Colors.green;
      case 'sale':
        return Colors.orange;
      case 'lease':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: Colors.green,
      elevation: 4,
      child: Icon(
        _scrollOffset > 100 ? Icons.arrow_upward : Icons.search,
        color: Colors.white,
      ),
    );
  }
}
