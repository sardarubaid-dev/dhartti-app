import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/constants.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:dhartti/service/area_guideService.dart';
import 'package:dhartti/Model/area_guide_propertyModel.dart';

class AreaGuideDetailScreen extends StatefulWidget {
  final String societyName;
  final String cityName;
  final String? imageUrl;
  final int propertiesCount;

  const AreaGuideDetailScreen({
    super.key,
    required this.societyName,
    required this.cityName,
    this.imageUrl,
    this.propertiesCount = 0,
  });

  @override
  State<AreaGuideDetailScreen> createState() => _AreaGuideDetailScreenState();
}

class _AreaGuideDetailScreenState extends State<AreaGuideDetailScreen> {
  final AreaGuideService _service = AreaGuideService(
    baseUrl: AppConstants.baseUrl,
    imageUrl: AppConstants.baseUrl.replaceAll('/api', ''),
  );

  late Future<List<PropertyAreaGuide>> _societyPropertiesFuture;

  @override
  void initState() {
    super.initState();
    _societyPropertiesFuture = _loadProperties();
  }

  Future<List<PropertyAreaGuide>> _loadProperties() async {
    try {
      final results = await _service.searchProperties(
        city: widget.cityName.toLowerCase(),
      );
      final query = widget.societyName.toLowerCase();
      final filtered = results.where((p) {
        final title = (p.title ?? '').toLowerCase();
        final city = (p.city ?? '').toLowerCase();
        final desc = (p.description ?? '').toLowerCase();
        return title.contains(query) || city.contains(query) || desc.contains(query);
      }).toList();
      return filtered.isNotEmpty ? filtered : results.take(6).toList();
    } catch (_) {
      return [];
    }
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
      return 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&q=80';
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collapsible Header Image
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.societyName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _resolveImage(widget.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: primaryColor,
                      child: const Icon(Icons.location_city, size: 60, color: Colors.white54),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Pill Card
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
                                    Icon(Icons.location_on, color: primaryColor, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.societyName}, ${widget.cityName}',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${widget.propertiesCount > 0 ? widget.propertiesCount : '50+'} Properties',
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A premier master-planned housing development providing modern municipal infrastructure, underground utilities, lush green parks, reputable schools, commercial civic centers, and 24/7 gated security.',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Key Highlights
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
                            Text(
                              'Society Facilities & Amenities',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildAmenityChip(Icons.security_rounded, '24/7 Gated Security'),
                                _buildAmenityChip(Icons.park_outlined, 'Parks & Green Belts'),
                                _buildAmenityChip(Icons.local_hospital_outlined, 'Hospitals & Clinics'),
                                _buildAmenityChip(Icons.school_outlined, 'Top Tier Schools'),
                                _buildAmenityChip(Icons.shopping_bag_outlined, 'Commercial Hubs'),
                                _buildAmenityChip(Icons.mosque_outlined, 'Jamia Mosques'),
                                _buildAmenityChip(Icons.electric_bolt_outlined, 'Uninterrupted Power'),
                                _buildAmenityChip(Icons.fitness_center_outlined, 'Sports & Gym Complex'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Average Price Guide Table
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
                            Text(
                              'Average Property Prices in ${widget.societyName}',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildPriceRow('5 Marla House', 'PKR 1.25 Cr - 1.95 Cr'),
                            _buildPriceRow('10 Marla House', 'PKR 2.40 Cr - 3.80 Cr'),
                            _buildPriceRow('1 Kanal Luxury Villa', 'PKR 4.50 Cr - 7.50 Cr'),
                            _buildPriceRow('5 Marla Residential Plot', 'PKR 45 Lakh - 85 Lakh'),
                            _buildPriceRow('10 Marla Residential Plot', 'PKR 85 Lakh - 1.60 Cr'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Available Properties in this society
                      Text(
                        'Properties for Sale & Rent in this Area',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      FutureBuilder<List<PropertyAreaGuide>>(
                        future: _societyPropertiesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            );
                          }

                          final properties = snapshot.data ?? [];
                          if (properties.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  'No current active listings in this immediate area.',
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: properties.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final prop = properties[idx];
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SizedBox(
                                          width: 90,
                                          height: 75,
                                          child: Image.network(
                                            _resolveImage(prop.imagePath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.home, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _formatPrice(prop.price ?? 0),
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              prop.title ?? 'Listing',
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${prop.bedrooms ?? 0} Beds • ${prop.bathrooms ?? 0} Baths • ${prop.areaSize ?? ''} ${prop.areaUnit ?? ''}',
                                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              );
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
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF108224)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String type, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
          Text(price, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
