import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/Model/Bid.dart';
import 'package:dhartti/Model/project_model.dart';
import 'package:dhartti/UserScreen/ProjectScreen/EditProjectScreen.dart';
import 'package:dhartti/service/Bid_service.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:dhartti/service/seller_service.dart';

class UserProjectDetailPage extends StatefulWidget {
  final int projectId;

  const UserProjectDetailPage({Key? key, required this.projectId}) : super(key: key);

  @override
  _UserProjectDetailPageState createState() => _UserProjectDetailPageState();
}

class _UserProjectDetailPageState extends State<UserProjectDetailPage> {
  late Future<Project> _projectFuture;
  final ProjectService _projectService = ProjectService();
  final BidService _bidService = BidService();
  final SellerService _sellerService = SellerService();
  int _bidCount = 0;
  late Future<List<Bid>> _bidsFuture;

  late PageController _imagePageController;
  int _activeImageIndex = 0;
  Timer? _autoSlideTimer;

  static const Color primaryGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _fetchData();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int imageCount) {
    if (imageCount <= 1) return;
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_imagePageController.hasClients) return;
      final next = (_activeImageIndex + 1) % imageCount;
      _imagePageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _projectFuture = _projectService.fetchProject(widget.projectId);
      _bidsFuture = _bidService.getBids(widget.projectId);
    });
    await _fetchBidCount();
  }

  Future<void> _fetchBidCount() async {
    try {
      final count = await _bidService.getBidCount(widget.projectId);
      if (mounted) {
        setState(() {
          _bidCount = count;
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  String _formatCurrency(num? amount) {
    if (amount == null || amount == 0) return 'PKR 0';
    final val = amount.toDouble();
    if (val >= 10000000) {
      return 'PKR ${(val / 10000000).toStringAsFixed(2)} Crore';
    } else if (val >= 100000) {
      return 'PKR ${(val / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return 'PKR ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  String _formatBudgetRange(Project p) {
    final min = p.budgetRangeMin;
    final max = p.budgetRangeMax;
    if (min > 0 && max > 0) {
      return '${_formatCurrency(min)} - ${_formatCurrency(max)}';
    } else if (min > 0) {
      return 'From ${_formatCurrency(min)}';
    } else if (max > 0) {
      return 'Up to ${_formatCurrency(max)}';
    }
    return 'Price on Inquiry';
  }

  String _formatAreaRange(List<dynamic> list, String unit) {
    if (list.isEmpty) return 'Flexible Area';
    final first = list.first;
    if (first is Map) {
      final min = first['min']?.toString() ?? '';
      final max = first['max']?.toString() ?? '';
      if (min.isNotEmpty && max.isNotEmpty) {
        return '$min - $max $unit';
      } else if (min.isNotEmpty) {
        return '$min $unit';
      }
    }
    return '${list.join(' - ')} $unit';
  }

  void _showBidDialog(BuildContext context) {
    final TextEditingController bidPriceController = TextEditingController();
    final TextEditingController bidDescriptionController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.gavel, color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Place Contractor Bid',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Proposed Bid Amount (PKR) *',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: bidPriceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2500000',
                    prefixText: 'PKR ',
                    prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scope & Notes (Optional)',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: bidDescriptionController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter milestones, construction schedule, or materials included...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final price = double.tryParse(bidPriceController.text.trim());
                            if (price == null || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid bid amount')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await _bidService.submitBid(
                                widget.projectId,
                                price,
                                bidDescriptionController.text.trim(),
                              );
                              if (bottomSheetCtx.mounted) Navigator.pop(bottomSheetCtx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Bid submitted successfully!', style: GoogleFonts.poppins(color: Colors.white)),
                                    backgroundColor: primaryGreen,
                                  ),
                                );
                                _fetchData();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            'Submit Bid',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBidDecisionDialog(Bid bid, String targetStatus) {
    final replyController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '$targetStatus Bid',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: targetStatus == 'Accepted' ? primaryGreen : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this bid as $targetStatus?',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyController,
                maxLines: 2,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Message to Bidder (Optional)',
                  labelStyle: GoogleFonts.poppins(fontSize: 12),
                  hintText: 'e.g. Please visit our office on Monday for agreement...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final res = await _sellerService.updateProjectBidStatus(
                        bid.id,
                        targetStatus,
                        ownerReply: replyController.text.trim().isNotEmpty ? replyController.text.trim() : null,
                      );
                      setDialogState(() => isSubmitting = false);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Bid updated'),
                            backgroundColor: res['success'] == true ? primaryGreen : Colors.red,
                          ),
                        );
                        if (res['success'] == true) {
                          _fetchData();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: targetStatus == 'Accepted' ? primaryGreen : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm $targetStatus', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(
          'Project Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Project',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProjectScreen(projectId: widget.projectId),
                ),
              );
              _fetchData();
            },
          ),
        ],
      ),
      body: FutureBuilder<Project>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text('Failed to load project details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(snapshot.error.toString(), style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchData,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text('No project details found.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
            );
          }

          final project = snapshot.data!;
          final images = project.allImages;
          if (_autoSlideTimer == null && images.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide(images.length));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Carousel
                _buildHeroSlider(images),

                // Main Content Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Developer
                      Text(
                        project.title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      if (project.developerTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business, color: primaryGreen, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'By ${project.developerTitle}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Tags Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (project.city.isNotEmpty)
                            _buildTag(icon: Icons.location_on, label: project.city, color: Colors.red.shade700, bg: Colors.red.shade50),
                          if (project.propertyType.isNotEmpty)
                            _buildTag(icon: Icons.apartment, label: project.propertyType, color: primaryGreen, bg: primaryGreen.withOpacity(0.1)),
                          if (project.offering.isNotEmpty)
                            _buildTag(icon: Icons.local_offer_outlined, label: project.offering, color: Colors.blue.shade700, bg: Colors.blue.shade50),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Highlighted Budget & Area Overview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF108224), Color(0xFF0D681C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PROJECT BUDGET RANGE',
                                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatBudgetRange(project),
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    project.currency.isNotEmpty ? project.currency : 'PKR',
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.square_foot, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Area Range: ${_formatAreaRange(project.areaRange, project.areaUnit)}',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      if (project.description.isNotEmpty) ...[
                        Text(
                          'Project Overview',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            project.description,
                            style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF334155), height: 1.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Specifications & Addresses
                      Text(
                        'Project Specifications',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildSpecRow(icon: Icons.location_city, label: 'Target City', value: project.city.isNotEmpty ? project.city : 'Pakistan'),
                            const Divider(height: 16),
                            _buildSpecRow(icon: Icons.home_work_outlined, label: 'Property Classification', value: project.propertyType.isNotEmpty ? project.propertyType : 'Development'),
                            const Divider(height: 16),
                            _buildSpecRow(icon: Icons.layers_outlined, label: 'Area Unit Type', value: project.areaUnit.toUpperCase()),
                            if (project.addresses.isNotEmpty) ...[
                              const Divider(height: 16),
                              _buildSpecRow(icon: Icons.pin_drop_outlined, label: 'Project Addresses', value: project.addresses.map((a) => a is Map ? (a['line'] ?? a.toString()) : a.toString()).join('\n')),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Bidding Management Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.gavel, color: Colors.purple.shade700, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Contractor Bids ($_bidCount)',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showBidDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Place Bid', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bids List
                      FutureBuilder<List<Bid>>(
                        future: _bidsFuture,
                        builder: (context, bidSnapshot) {
                          if (bidSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryGreen)));
                          }
                          final bids = bidSnapshot.data ?? [];
                          if (bids.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.gavel_outlined, size: 36, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No Bids Submitted Yet',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    'Contractor proposals and bids for this project will appear here.',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bids.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildBidCard(bids[index]);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSlider(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: const Color(0xFFE2E8F0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apartment_rounded, color: Colors.grey.shade400, size: 54),
              const SizedBox(height: 6),
              Text('No Images Available', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _activeImageIndex = i),
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE2E8F0),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 48),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Left / Right Chevrons
        if (images.length > 1) ...[
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final prev = (_activeImageIndex - 1 + images.length) % images.length;
                  _imagePageController.animateToPage(prev, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final next = (_activeImageIndex + 1) % images.length;
                  _imagePageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],

        // Counter Chip & Dots
        if (images.length > 1) ...[
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activeImageIndex + 1}/${images.length}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => GestureDetector(
                  onTap: () => _imagePageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _activeImageIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _activeImageIndex == i ? primaryGreen : Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTag({required IconData icon, required String label, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSpecRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(value, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBidCard(Bid bid) {
    final status = bid.status;
    Color statusColor = Colors.orange.shade700;
    Color statusBg = Colors.orange.shade50;
    if (status == 'Accepted') {
      statusColor = primaryGreen;
      statusBg = primaryGreen.withOpacity(0.1);
    } else if (status == 'Rejected') {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryGreen.withOpacity(0.12),
                child: Text(
                  (bid.username != null && bid.username!.isNotEmpty) ? bid.username![0].toUpperCase() : 'C',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.username ?? 'Contractor / Bidder',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      _formatCurrency(double.tryParse(bid.bidPrice?.toString() ?? '0')),
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: primaryGreen),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          if (bid.bidDescription != null && bid.bidDescription!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bid.bidDescription!,
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
            ),
          ],

          if (bid.ownerReply != null && bid.ownerReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Your Reply: ${bid.ownerReply}',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF334155), fontStyle: FontStyle.italic),
              ),
            ),
          ],

          if (status == 'Pending') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showBidDecisionDialog(bid, 'Rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('Reject Bid', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBidDecisionDialog(bid, 'Accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('Accept Bid', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
