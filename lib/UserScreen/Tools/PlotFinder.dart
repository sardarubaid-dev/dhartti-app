import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PropertyService _propertyService = PropertyService();
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  // Default Pakistan Center (Islamabad)
  static const LatLng _initialCenter = LatLng(33.6844, 73.0479);

  bool _isLoading = true;
  String _selectedCity = 'All';
  String _selectedCategory = 'All'; // 'All', 'plots', 'home', 'commercial'
  Map<String, dynamic>? _selectedPlot;

  final List<Map<String, dynamic>> _cities = [
    {'name': 'All', 'lat': 30.3753, 'lng': 69.3451, 'zoom': 6.0},
    {'name': 'Islamabad', 'lat': 33.6844, 'lng': 73.0479, 'zoom': 12.0},
    {'name': 'Rawalpindi', 'lat': 33.5651, 'lng': 73.0169, 'zoom': 12.0},
    {'name': 'Lahore', 'lat': 31.5204, 'lng': 74.3587, 'zoom': 12.0},
    {'name': 'Karachi', 'lat': 24.8607, 'lng': 67.0011, 'zoom': 11.5},
    {'name': 'Peshawar', 'lat': 34.0151, 'lng': 71.5249, 'zoom': 12.0},
    {'name': 'Multan', 'lat': 30.1575, 'lng': 71.5249, 'zoom': 12.0},
    {'name': 'Faisalabad', 'lat': 31.4504, 'lng': 73.1350, 'zoom': 12.0},
    {'name': 'Abbottabad', 'lat': 34.1688, 'lng': 73.2215, 'zoom': 12.0},
  ];

  final Map<String, LatLng> _cityCoordinates = {
    'islamabad': LatLng(33.6844, 73.0479),
    'rawalpindi': LatLng(33.5651, 73.0169),
    'lahore': LatLng(31.5204, 74.3587),
    'karachi': LatLng(24.8607, 67.0011),
    'peshawar': LatLng(34.0151, 71.5249),
    'multan': LatLng(30.1575, 71.5249),
    'faisalabad': LatLng(31.4504, 73.1350),
    'abbottabad': LatLng(34.1688, 73.2215),
  };

  List<Map<String, dynamic>> _properties = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rawList = await _propertyService.fetchProperties();
      final List<Map<String, dynamic>> mapped = [];

      for (int i = 0; i < rawList.length; i++) {
        final item = Map<String, dynamic>.from(rawList[i]);
        final city = (item['city'] ?? 'Islamabad').toString().trim();
        final cityKey = city.toLowerCase();

        double lat = 0.0;
        double lng = 0.0;

        if (item['latitude'] != null && item['latitude'].toString().trim().isNotEmpty) {
          lat = double.tryParse(item['latitude'].toString()) ?? 0.0;
        }
        if (item['longitude'] != null && item['longitude'].toString().trim().isNotEmpty) {
          lng = double.tryParse(item['longitude'].toString()) ?? 0.0;
        }

        // Production Fallback: If property doesn't have exact lat/lng, jitter around its city center
        if (lat == 0.0 || lng == 0.0) {
          final baseCoord = _cityCoordinates[cityKey] ?? _initialCenter;
          // Slight jitter so markers don't overlap completely on the exact same spot
          final double jitterLat = ((i * 17) % 30 - 15) * 0.0035;
          final double jitterLng = ((i * 23) % 30 - 15) * 0.0035;
          lat = baseCoord.latitude + jitterLat;
          lng = baseCoord.longitude + jitterLng;
        }

        mapped.add({
          'id': item['id']?.toString() ?? '$i',
          'numeric_id': item['id'] != null ? int.tryParse(item['id'].toString()) : null,
          'title': item['title'] ?? 'Real Estate Property',
          'city': city,
          'society': item['plot_number'] ?? item['sub_property_type'] ?? city,
          'property_type': (item['property_type'] ?? 'plots').toString().toLowerCase(),
          'sub_property_type': item['sub_property_type'] ?? '',
          'size': '${item['area_size'] ?? ''} ${item['area_unit'] ?? ''}'.trim(),
          'price_num': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
          'price': _formatPrice(item['price']),
          'lat': lat,
          'lng': lng,
          'image': PropertyService.formatPropertyImageUrl(item['image_path']),
          'phone': _extractPhone(item['mobile_numbers']),
          'purpose': item['purpose'] ?? 'Sale',
          'status': item['ready_for_possession'] == true ? 'Ready Possession' : 'Active Listing',
        });
      }

      if (mounted) {
        setState(() {
          _properties = mapped;
          _isLoading = false;
        });
        _buildMarkers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return 'PKR Price on Call';
    final double? price = double.tryParse(rawPrice.toString());
    if (price == null || price <= 0) return 'PKR Price on Call';

    if (price >= 10000000) {
      return 'PKR ${(price / 10000000).toStringAsFixed(2)} Crore';
    } else if (price >= 100000) {
      return 'PKR ${(price / 100000).toStringAsFixed(2)} Lakh';
    } else if (price >= 1000) {
      return 'PKR ${(price / 1000).toStringAsFixed(0)}K';
    }
    return 'PKR ${price.toStringAsFixed(0)}';
  }

  String _extractPhone(dynamic rawNumbers) {
    if (rawNumbers == null) return '';
    try {
      if (rawNumbers is List && rawNumbers.isNotEmpty) {
        return rawNumbers.first.toString();
      }
      final str = rawNumbers.toString();
      if (str.startsWith('[')) {
        final cleaned = str.replaceAll(RegExp(r'[\[\]\\"\s]'), '');
        final parts = cleaned.split(',');
        if (parts.isNotEmpty) return parts.first;
      }
      return str;
    } catch (_) {
      return '';
    }
  }

  void _buildMarkers() {
    final Set<Marker> newMarkers = {};

    final filtered = _getFilteredProperties();

    for (var plot in filtered) {
      final pType = plot['property_type'];
      double hue = BitmapDescriptor.hueGreen;
      if (pType == 'commercial') {
        hue = BitmapDescriptor.hueAzure;
      } else if (pType == 'home') {
        hue = BitmapDescriptor.hueOrange;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(plot['id']),
          position: LatLng(plot['lat'], plot['lng']),
          infoWindow: InfoWindow(
            title: plot['title'],
            snippet: '${plot['size']} • ${plot['price']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            setState(() {
              _selectedPlot = plot;
            });
          },
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  List<Map<String, dynamic>> _getFilteredProperties() {
    return _properties.where((p) {
      // City filter
      if (_selectedCity != 'All' &&
          p['city'].toString().toLowerCase() != _selectedCity.toLowerCase()) {
        return false;
      }

      // Category filter
      if (_selectedCategory != 'All' &&
          p['property_type'].toString().toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // Search query
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final title = p['title'].toString().toLowerCase();
        final city = p['city'].toString().toLowerCase();
        final society = p['society'].toString().toLowerCase();
        if (!title.contains(q) && !city.contains(q) && !society.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _moveToCity(Map<String, dynamic> city) {
    setState(() {
      _selectedCity = city['name'];
      _buildMarkers();
    });

    final filtered = _getFilteredProperties();
    if (filtered.isNotEmpty) {
      _selectedPlot = filtered.first;
    } else {
      _selectedPlot = null;
    }

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(city['lat'], city['lng']),
          zoom: city['zoom'],
        ),
      ),
    );
  }

  void _searchLocation(String query) {
    setState(() {
      _buildMarkers();
    });

    final filtered = _getFilteredProperties();
    if (filtered.isNotEmpty) {
      final first = filtered.first;
      setState(() {
        _selectedPlot = first;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(first['lat'], first['lng']), 14.5),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No properties found for "$query"'),
          backgroundColor: const Color(0xFF108224),
        ),
      );
    }
  }

  void _callAgent(String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact number not available for this listing')),
      );
      return;
    }
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch dialer for $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Property & Plot Finder',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF108224),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh Listings',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProperties,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: _initialCenter,
              zoom: 11.5,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (_) {
              setState(() {
                _selectedPlot = null;
              });
            },
          ),

          // Loading overlay indicator
          if (_isLoading)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Fetching live database plots...',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top Controls (Search bar + Category Filters + City filter pills)
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _searchLocation,
                    decoration: InputDecoration(
                      hintText: 'Search society, sector or title...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF108224)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _searchLocation('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Chips (Plots, Houses, Commercial)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildCategoryChip('All Listings', 'All', Icons.grid_view_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Plots Only', 'plots', Icons.landscape_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Houses / Homes', 'home', Icons.home_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Commercial', 'commercial', Icons.storefront_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // City Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _cities.map((c) {
                      final isSelected = _selectedCity.toLowerCase() == c['name'].toString().toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _moveToCity(c),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF108224) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: isSelected ? const Color(0xFF108224) : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              c['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Plot Card overlay when marker is tapped
          if (_selectedPlot != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildPlotDetailsCard(_selectedPlot!),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, IconData icon) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = value;
          _buildMarkers();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlotDetailsCard(Map<String, dynamic> plot) {
    final pType = plot['property_type'];
    final isCommercial = pType == 'commercial';
    final hasImage = plot['image'] != null && plot['image'].toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image or Fallback Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        plot['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackIcon(isCommercial, pType),
                      )
                    : _buildFallbackIcon(isCommercial, pType),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${plot['society']}, ${plot['city']}',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() => _selectedPlot = null);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Size',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    plot['size'].toString().isEmpty ? 'N/A' : plot['size'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Demand Price',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    plot['price'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF108224),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plot['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              const Spacer(),
              // Call Agent Button
              if (plot['phone'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _callAgent(plot['phone']),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF108224)),
                      ),
                      child: const Icon(Icons.phone, size: 16, color: Color(0xFF108224)),
                    ),
                  ),
                ),
              // View Full Details Screen Button
              ElevatedButton.icon(
                onPressed: () {
                  final int? propId = plot['numeric_id'];
                  if (propId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailPage(propertyId: propId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing ${plot['title']}')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF108224),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Details',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(bool isCommercial, String pType) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isCommercial
            ? Colors.blue.shade50
            : (pType == 'home' ? Colors.orange.shade50 : const Color(0xFFE8F5E9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isCommercial
            ? Icons.storefront
            : (pType == 'home' ? Icons.home_rounded : Icons.landscape_rounded),
        color: isCommercial
            ? Colors.blue.shade800
            : (pType == 'home' ? Colors.orange.shade800 : const Color(0xFF108224)),
        size: 26,
      ),
    );
  }
}
