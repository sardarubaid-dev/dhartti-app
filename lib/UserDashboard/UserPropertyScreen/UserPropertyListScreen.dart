import 'package:dhartti/Model/property_model.dart';
import 'package:dhartti/Model/superproperty_model.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/service/seller_service.dart';
import 'package:dhartti/UserScreen/PropertyScreen/EditPropertyScreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:flutter/material.dart';

class UserPanelPropertyListScreen extends StatefulWidget {
  const UserPanelPropertyListScreen({Key? key}) : super(key: key);

  @override
  _UserPanelPropertyListScreenState createState() => _UserPanelPropertyListScreenState();
}

class _UserPanelPropertyListScreenState extends State<UserPanelPropertyListScreen> {
  late Future<List<PropertySuperAdmin>> _propertys;
  final ScrollController _scrollController = ScrollController();
  final SellerService _sellerService = SellerService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedPurpose = 'All'; // 'All', 'sale', 'rent'
  String _searchQuery = '';
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initializePropertys();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _initializePropertys() {
    try {
      _propertys = PropertyService().fetchUserPanelPropertys();
    } catch (e) {
      _propertys = Future.error(e);
    }
  }

  void _refreshProperties() {
    setState(() {
      _initializePropertys();
    });
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

  Future<void> _deleteProperty(int id, String? title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Property',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete this property listing?',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                title?.isNotEmpty == true ? title! : 'Untitled Property',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone and will remove all associated inquiries.',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final success = await _sellerService.deleteProperty(id);
        if (mounted) {
          setState(() => _isDeleting = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Property deleted successfully'),
                  ],
                ),
                backgroundColor: Color(0xFF108224),
              ),
            );
            _refreshProperties();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Failed to delete property. Please try again.'),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Convert PropertySuperAdmin to Property for editing
  Property _convertToProperty(PropertySuperAdmin superProperty) {
    return Property(
      id: superProperty.id,
      purpose: superProperty.purpose,
      propertyType: superProperty.propertyType,
      subPropertyType: superProperty.subPropertyType,
      city: superProperty.city,
      areaSize: superProperty.areaSize != null ? double.tryParse(superProperty.areaSize.toString()) : null,
      areaUnit: superProperty.areaUnit,
      price: superProperty.price != null ? double.tryParse(superProperty.price.toString()) : null,
      currency: superProperty.currency,
      installmentAvailable: superProperty.installmentAvailable,
      advanceAmount: superProperty.advanceAmount != null ? double.tryParse(superProperty.advanceAmount.toString()) : null,
      monthlyInstallment: superProperty.monthlyInstallment != null ? double.tryParse(superProperty.monthlyInstallment.toString()) : null,
      readyForPossession: superProperty.readyForPossession,
      bedrooms: superProperty.bedrooms,
      bathrooms: superProperty.bathrooms,
      title: superProperty.title,
      description: superProperty.description,
      imagePath: superProperty.imagePath,
      email: superProperty.email,
      mobileNumbers: superProperty.mobileNumbers is List
          ? List<String>.from(superProperty.mobileNumbers)
          : (superProperty.mobileNumbers != null ? [superProperty.mobileNumbers.toString()] : null),
      landline: superProperty.landline,
      userId: superProperty.userId,
      whatsappNumber: superProperty.whatsappNumber,
      imagePath2: superProperty.imagePath2,
      imagePath3: superProperty.imagePath3,
      imagePath4: superProperty.imagePath4,
      imagePath5: superProperty.imagePath5,
    );
  }

  void _navigateToEditScreen(PropertySuperAdmin superProperty) {
    try {
      final property = _convertToProperty(superProperty);
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => EditPropertyScreen(property: property),
        ),
      ).then((updated) {
        if (updated == true || updated == null) {
          _refreshProperties();
        }
      });
    } catch (e) {
      debugPrint('Error navigating to edit screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open edit screen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<PropertySuperAdmin> _filterProperties(List<PropertySuperAdmin> properties) {
    return properties.where((p) {
      // Filter by Purpose
      if (_selectedPurpose != 'All') {
        final purposeStr = (p.purpose ?? '').toLowerCase();
        if (_selectedPurpose == 'sale' && !purposeStr.contains('sale')) return false;
        if (_selectedPurpose == 'rent' && !purposeStr.contains('rent')) return false;
      }

      // Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        final title = (p.title ?? '').toLowerCase();
        final city = (p.city ?? '').toLowerCase();
        final type = (p.propertyType ?? '').toLowerCase();
        final subtype = (p.subPropertyType ?? '').toLowerCase();

        final match = title.contains(_searchQuery) ||
            city.contains(_searchQuery) ||
            type.contains(_searchQuery) ||
            subtype.contains(_searchQuery);

        if (!match) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF108224);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Properties',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _refreshProperties,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPropertyScreen()),
          ).then((_) => _refreshProperties());
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Add Property', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: primaryColor,
            onRefresh: () async => _refreshProperties(),
            child: FutureBuilder<List<PropertySuperAdmin>>(
              future: _propertys,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isSearch: false);
                }

                final allProperties = snapshot.data!;
                final filtered = _filterProperties(allProperties);

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Filter & Search Area
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total count & stats pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'My Listings (${filtered.length} of ${allProperties.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${allProperties.length} Total',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Search Box
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by title, city, or type...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => _searchController.clear(),
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Filter Chips (All, For Sale, For Rent)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All', 'All'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('For Sale', 'sale'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('For Rent', 'rent'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Properties List or Filter Empty State
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(isSearch: true),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final property = filtered[index];
                              return _buildModernPropertyCard(property);
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        SizedBox(width: 16),
                        Text('Deleting property...', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedPurpose == value;
    const primaryColor = Color(0xFF108224);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedPurpose = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPropertyCard(PropertySuperAdmin property) {
    const primaryColor = Color(0xFF108224);
    final purpose = (property.purpose ?? 'Sale').toUpperCase();
    final isRent = purpose.contains('RENT');
    final formattedPrice = _formatPrice(property.price, property.purpose);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (property.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyDetailPage(propertyId: property.id!),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Thumbnail with Floating Badges
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: property.imagePath != null && property.imagePath!.isNotEmpty
                        ? Image.network(
                            property.imagePath!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 4),
                                    Text('No preview available', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_work_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 4),
                                Text('Dhartti Property', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                  ),

                  // Purpose & Hot Badges (Top Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isRent ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Text(
                            isRent ? 'FOR RENT' : 'FOR SALE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (property.isSuperHot == true) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.local_fire_department, color: Colors.white, size: 13),
                                SizedBox(width: 2),
                                Text(
                                  'SUPER HOT',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (property.isActive ?? true) ? primaryColor : Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (property.isActive ?? true) ? Icons.check_circle : Icons.schedule,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (property.isActive ?? true) ? 'Active' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Property Details Body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      property.title?.isNotEmpty == true ? property.title! : 'Untitled Property',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // City Location Row
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.city?.isNotEmpty == true ? property.city! : 'Pakistan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Specs Badges Row (Area, Beds, Baths, Type)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (property.areaSize != null)
                          _buildSpecChip(
                            Icons.straighten,
                            '${property.areaSize} ${property.areaUnit ?? 'Marla'}',
                          ),
                        if (property.bedrooms != null && property.bedrooms! > 0)
                          _buildSpecChip(
                            Icons.bed_outlined,
                            '${property.bedrooms} Beds',
                          ),
                        if (property.bathrooms != null && property.bathrooms! > 0)
                          _buildSpecChip(
                            Icons.bathtub_outlined,
                            '${property.bathrooms} Baths',
                          ),
                        if (property.propertyType != null)
                          _buildSpecChip(
                            Icons.home_outlined,
                            property.propertyType!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Action Buttons: Edit & Delete
                    Row(
                      children: [
                        // Edit Button
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToEditScreen(property),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(color: primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete Button
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: property.id != null
                                ? () => _deleteProperty(property.id!, property.title)
                                : null,
                            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade300),
                              backgroundColor: Colors.red.shade50.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isSearch}) {
    const primaryColor = Color(0xFF108224);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isSearch ? Colors.orange.shade50 : primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.home_work_outlined,
                size: 54,
                color: isSearch ? Colors.orange.shade700 : primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No Matching Properties Found' : 'No Properties Listed Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try adjusting your search query or purpose filters.'
                  : 'Start listing your properties to receive calls, WhatsApp inquiries, and bids from verified buyers across Pakistan.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isSearch)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedPurpose = 'All');
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Reset Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPropertyScreen()),
                  ).then((_) => _refreshProperties());
                },
                icon: const Icon(Icons.add_home_outlined),
                label: const Text('List Your First Property', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    const primaryColor = Color(0xFF108224);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Properties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshProperties,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
