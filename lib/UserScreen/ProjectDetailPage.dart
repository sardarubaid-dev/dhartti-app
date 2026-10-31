import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/Model/Bid.dart';
import 'package:dhartti/Model/PropertyInquiry.dart';
import 'package:dhartti/Model/project_model.dart';
import 'package:dhartti/service/Bid_service.dart';
import 'package:dhartti/service/PropertyInquiryService.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryGreen = Color(0xFF108224);
const Color darkGreen = Color(0xFF0D681C);

class ProjectDetailPage extends StatefulWidget {
  final int projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late Future<Project> _projectFuture;
  Future<List<Bid>>? _bidsFuture;
  final ProjectService _projectService = ProjectService();
  final BidService _bidService = BidService();
  int _bidCount = 0;
  int? _currentUserId;
  bool _hasPlacedBid = false;
  bool _isBiddingClosed = false;
  Bid? _currentUserBid;
  String? _selectedInquiryType = 'buyer';
  bool _isSubmittingInquiry = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inquiryKey = GlobalKey();

  // Slider controls
  late final PageController _imagePageController;
  int _activeImageIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _loadUserId();
    _fetchData();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawUserId = prefs.get('userId');
    final userId = rawUserId is int ? rawUserId : (rawUserId is String ? int.tryParse(rawUserId) : null);
    if (mounted) {
      setState(() => _currentUserId = userId);
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _imagePageController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoSlide(int totalImages) {
    _autoSlideTimer?.cancel();
    if (totalImages <= 1) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_imagePageController.hasClients) return;
      final next = (_activeImageIndex + 1) % totalImages;
      _imagePageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _projectFuture = _projectService.fetchProject(widget.projectId);
      _bidsFuture = _bidService.getBids(widget.projectId).then((bids) {
        if (mounted) {
          final hasAccepted = bids.any((b) => b.status.toLowerCase() == 'accepted');
          Bid? myBid;
          try {
            myBid = bids.firstWhere((b) =>
                (_currentUserId != null && b.userId == _currentUserId) ||
                (b.username != null && b.username!.contains('(You)')));
          } catch (_) {
            myBid = null;
          }
          setState(() {
            _hasPlacedBid = myBid != null;
            _currentUserBid = myBid;
            _isBiddingClosed = hasAccepted;
          });
        }
        return bids;
      });
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
    } catch (_) {
      // Gracefully silent for guest or unauthenticated browsing
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    double val = 0;
    if (amount is num) {
      val = amount.toDouble();
    } else {
      val = double.tryParse(amount.toString().replaceAll(',', '').trim()) ?? 0;
    }
    if (val <= 0) return '0';
    if (val >= 10000000) {
      final cr = val / 10000000;
      return '${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Crore';
    } else if (val >= 100000) {
      final lac = val / 100000;
      return '${lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2)} Lakh';
    } else if (val >= 1000) {
      final k = val / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)} K';
    }
    return val.toStringAsFixed(0);
  }

  String _formatBudgetRange(Project p) {
    final min = p.budgetRangeMin;
    final max = p.budgetRangeMax;
    final curr = p.currency.isNotEmpty ? p.currency : 'PKR';
    if (min > 0 && max > 0) {
      return '$curr ${_formatCurrency(min)} - ${_formatCurrency(max)}';
    } else if (min > 0) {
      return 'Starting from $curr ${_formatCurrency(min)}';
    } else if (max > 0) {
      return 'Up to $curr ${_formatCurrency(max)}';
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

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate() || _selectedInquiryType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your inquiry message.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmittingInquiry = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawUserId = prefs.get('userId');
      final userId = rawUserId is int ? rawUserId : (rawUserId is String ? int.tryParse(rawUserId) : null);

      if (userId == null) {
        throw Exception('Please sign in to send an inquiry.');
      }

      final inquiry = PropertyInquiry(
        propertyId: widget.projectId,
        message: _messageController.text.trim(),
        inquiryType: _selectedInquiryType!,
      );

      final success = await PropertyInquiryService().submitInquiry(inquiry);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquiry submitted successfully! The developer will contact you.'),
              backgroundColor: primaryGreen,
            ),
          );
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit inquiry. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingInquiry = false);
    }
  }

  void _showBidDialog(BuildContext context, Project project, {Bid? existingBid}) {
    final bool isEditing = existingBid != null;
    String initialPrice = '';
    if (isEditing && existingBid.bidPrice != null) {
      final parsed = double.tryParse(existingBid.bidPrice!.replaceAll(',', '').trim());
      if (parsed != null && parsed > 0) {
        initialPrice = parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
      } else {
        initialPrice = existingBid.bidPrice!;
      }
    }
    final TextEditingController bidPriceController = TextEditingController(text: initialPrice);
    final TextEditingController bidDescriptionController = TextEditingController(
      text: isEditing ? (existingBid.bidDescription ?? '') : '',
    );
    final bidFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final double minBudget = project.budgetRangeMin;
    final double maxBudget = project.budgetRangeMax;
    double? minAllowed;
    double? maxAllowed;

    if (minBudget > 0 || maxBudget > 0) {
      final double effectiveMin = minBudget > 0 ? minBudget : maxBudget;
      final double effectiveMax = maxBudget > 0 ? maxBudget : minBudget;
      minAllowed = effectiveMin * 0.70;
      maxAllowed = effectiveMax * 1.30;
    } else {
      minAllowed = 1000;
      maxAllowed = 100000000; // 10 Crore
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: bidFormKey,
              child: SingleChildScrollView(
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
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(isEditing ? Icons.edit : Icons.gavel, color: primaryGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Edit Your Bid' : 'Place Project Bid',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? 'Update your proposal or contractor bidding price for this project.'
                          : 'Submit your proposal or contractor bidding price for this development project.',
                      style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    // Project Budget Guide Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Project Budget:',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              Text(
                                _formatBudgetRange(project),
                                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          if (minAllowed != null && maxAllowed != null && (minBudget > 0 || maxBudget > 0)) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Allowed Range (70%-130%):',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                Text(
                                  'PKR ${_formatCurrency(minAllowed)} - ${_formatCurrency(maxAllowed)}',
                                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryGreen),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bid Amount (PKR)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: bidPriceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.payments_outlined, color: primaryGreen),
                        hintText: minAllowed != null
                            ? 'e.g. ${minAllowed.toStringAsFixed(0)}'
                            : 'e.g. 2500000',
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your bid amount';
                        }
                        final clean = value.replaceAll(',', '').trim();
                        final price = double.tryParse(clean);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid numeric amount';
                        }
                        if (minAllowed != null && price < minAllowed) {
                          return 'Bid cannot be less than PKR ${_formatCurrency(minAllowed)} (70% of budget)';
                        }
                        if (maxAllowed != null && price > maxAllowed) {
                          return 'Bid cannot exceed PKR ${_formatCurrency(maxAllowed)} (130% of budget)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Proposal / Notes (Optional, max 500 chars)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: bidDescriptionController,
                      maxLines: 3,
                      maxLength: 500,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe timeline, payment terms, or project scope details...',
                        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'Proposal cannot exceed 500 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (bidFormKey.currentState!.validate()) {
                                  FocusScope.of(ctx).unfocus();
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final price = double.parse(bidPriceController.text.replaceAll(',', '').trim());
                                    if (isEditing) {
                                      await _bidService.updateBid(
                                        widget.projectId,
                                        existingBid.id,
                                        price,
                                        bidDescriptionController.text.trim(),
                                      );
                                    } else {
                                      await _bidService.submitBid(
                                        widget.projectId,
                                        price,
                                        bidDescriptionController.text.trim(),
                                      );
                                    }
                                    if (bottomSheetCtx.mounted) {
                                      Navigator.pop(bottomSheetCtx);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'Bid updated successfully!' : 'Bid submitted successfully!'),
                                          backgroundColor: primaryGreen,
                                        ),
                                      );
                                      _fetchData();
                                    }
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (mounted) {
                                      String errorMsg = e.toString().replaceAll('Exception: ', '').trim();
                                      if (errorMsg.contains('SQLSTATE') || errorMsg.contains('SQL:')) {
                                        errorMsg = 'Could not save bid due to database error. Please try again.';
                                      }
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMsg),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isEditing ? 'Updating Bid...' : 'Submitting Bid...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                isEditing ? 'UPDATE BID' : 'SUBMIT BID',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openImageZoom(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToInquiry() {
    if (_inquiryKey.currentContext != null) {
      Scrollable.ensureVisible(
        _inquiryKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<Project>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8FAFC),
              body: Center(child: CircularProgressIndicator(color: primaryGreen)),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: primaryGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Project Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              body: Center(
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
              ),
            );
          } else if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                backgroundColor: primaryGreen,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Project Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              body: Center(
                child: Text('No project details found.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
              ),
            );
          }

          final project = snapshot.data!;
          final images = project.allImages;
          if (_autoSlideTimer == null && images.length > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide(images.length));
          }

          return Stack(
            children: [
              // Scrollable Content
              Positioned.fill(
                bottom: 74, // Room for bottom sticky bar
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image Carousel
                      _buildHeroSlider(context, images),

                      // Main Body
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project Title
                            Text(
                              project.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            if (project.developerTitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.domain, color: primaryGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Developed by ${project.developerTitle}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),

                            // City & Tags Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (project.city.isNotEmpty)
                                  _buildTagChip(
                                    icon: Icons.location_on,
                                    label: project.city,
                                    color: Colors.red.shade700,
                                    bg: Colors.red.shade50,
                                  ),
                                if (project.propertyType.isNotEmpty)
                                  _buildTagChip(
                                    icon: Icons.apartment,
                                    label: project.propertyType,
                                    color: primaryGreen,
                                    bg: const Color(0xFFE8F5E9),
                                  ),
                                if (project.offering.isNotEmpty)
                                  _buildTagChip(
                                    icon: Icons.verified_outlined,
                                    label: project.offering,
                                    color: Colors.blue.shade700,
                                    bg: Colors.blue.shade50,
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.amber.shade700, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.8 (Verified)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Budget & Area Gradient Card
                            _buildBudgetGradientCard(project),

                            const SizedBox(height: 20),

                            // Gallery Thumbnails (if multiple images)
                            if (images.length > 1) ...[
                              Text(
                                'Project Gallery (${images.length} Photos)',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 75,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, idx) {
                                    final isSelected = _activeImageIndex == idx;
                                    return GestureDetector(
                                      onTap: () {
                                        _imagePageController.animateToPage(
                                          idx,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Container(
                                        width: 95,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? primaryGreen : Colors.grey.shade300,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            images[idx],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image, color: Colors.grey, size: 24),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Project Highlights & Description
                            if (project.description.isNotEmpty) ...[
                              Text(
                                'Project Overview',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
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
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    color: const Color(0xFF334155),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Overflow-free Specifications Card
                            Text(
                              'Key Specifications',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSpecificationsCard(project),

                            const SizedBox(height: 24),

                            // Contractor Bidding Section
                            _buildBiddingCard(context, project),

                            const SizedBox(height: 24),

                            // Direct Developer Inquiry Form
                            _buildInquirySection(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomActionBar(context, project),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // HERO IMAGE SLIDER
  // ==========================================
  Widget _buildHeroSlider(BuildContext context, List<String> images) {
    final hasImages = images.isNotEmpty;
    final count = hasImages ? images.length : 1;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        children: [
          // PageView Slider
          PageView.builder(
            controller: _imagePageController,
            itemCount: count,
            onPageChanged: (idx) {
              setState(() => _activeImageIndex = idx);
            },
            itemBuilder: (context, index) {
              if (!hasImages) {
                return Container(
                  color: const Color(0xFFE2E8F0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apartment_rounded, color: Colors.grey.shade400, size: 54),
                        const SizedBox(height: 8),
                        Text(
                          'Dhartti Development Project',
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final imgUrl = images[index];
              return GestureDetector(
                onTap: () => _openImageZoom(context, imgUrl),
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 48),
                    ),
                  ),
                ),
              );
            },
          ),

          // Gradient overlay top and bottom
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(120),
                      Colors.transparent,
                      Colors.black.withAlpha(150),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Top Navigation Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                        tooltip: 'Share Project',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Project link copied to clipboard!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Left / Right Chevrons
          if (hasImages && images.length > 1) ...[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    final prev = (_activeImageIndex - 1 + images.length) % images.length;
                    _imagePageController.animateToPage(
                      prev,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
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
                    _imagePageController.animateToPage(
                      next,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
          ],

          // Counter Chip & Dots
          if (hasImages && images.length > 1) ...[
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_activeImageIndex + 1}/${images.length}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
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
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _activeImageIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _activeImageIndex == index ? primaryGreen : Colors.white60,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // BUDGET & AREA GRADIENT CARD
  // ==========================================
  Widget _buildBudgetGradientCard(Project project) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withAlpha(70),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                'PROJECT BUDGET RANGE',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.currency.isNotEmpty ? project.currency : 'PKR',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatBudgetRange(project),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.straighten_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Area Range: ${_formatAreaRange(project.areaRange, project.areaUnit)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SPECIFICATIONS CARD (NO OVERFLOWS)
  // ==========================================
  Widget _buildSpecificationsCard(Project project) {
    final addressesText = project.addresses.isNotEmpty
        ? project.addresses.map((a) => a is Map ? (a['line'] ?? a.toString()) : a.toString()).join(', ')
        : (project.city.isNotEmpty ? project.city : 'Pakistan');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSpecRow(
            icon: Icons.business_outlined,
            label: 'Property Type',
            value: project.propertyType.isNotEmpty ? project.propertyType : 'Development Project',
          ),
          const Divider(height: 18),
          _buildSpecRow(
            icon: Icons.local_offer_outlined,
            label: 'Offering',
            value: project.offering.isNotEmpty ? project.offering : 'For Sale',
          ),
          const Divider(height: 18),
          _buildSpecRow(
            icon: Icons.domain,
            label: 'Developer',
            value: project.developerTitle.isNotEmpty ? project.developerTitle : 'Independent Developer',
          ),
          const Divider(height: 18),
          _buildSpecRow(
            icon: Icons.layers_outlined,
            label: 'Unit Metric',
            value: project.areaUnit.toUpperCase(),
          ),
          const Divider(height: 18),
          _buildSpecRow(
            icon: Icons.location_on_outlined,
            label: 'Target City',
            value: project.city.isNotEmpty ? project.city : 'Pakistan',
          ),
          if (addressesText.isNotEmpty) ...[
            const Divider(height: 18),
            _buildSpecRow(
              icon: Icons.pin_drop_outlined,
              label: 'Location / Address',
              value: addressesText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ==========================================
  // BIDDING SECTION
  // ==========================================
  Widget _buildBiddingCard(BuildContext context, Project project) {
    return Container(
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
                    'Contractor Bidding',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_bidCount Bids Placed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Certified builders and contractors can bid directly on this project. Transparent negotiations with the project developer.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600, height: 1.5),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Bid>>(
            future: _bidsFuture,
            builder: (context, bidSnapshot) {
              final bids = bidSnapshot.data ?? [];
              final hasAcceptedBid = bids.any((b) => b.status.toLowerCase() == 'accepted');
              final hasMyBid = bids.any((b) =>
                  (_currentUserId != null && b.userId == _currentUserId) ||
                  (b.username != null && b.username!.contains('(You)')));
              final isOwner = _currentUserId != null && project.userId == _currentUserId;

              Widget actionButton;
              if (isOwner) {
                actionButton = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasAcceptedBid
                              ? 'Contractor proposal accepted (Bidding closed)'
                              : 'You are the project owner (Bidding disabled)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (hasAcceptedBid) {
                Bid? myBid;
                try {
                  myBid = bids.firstWhere(
                    (b) => (_currentUserId != null && b.userId == _currentUserId) ||
                        (b.username != null && b.username!.contains('(You)')),
                  );
                } catch (_) {
                  myBid = null;
                }
                final isMyBidAccepted = myBid != null && myBid.status.toLowerCase() == 'accepted';

                actionButton = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMyBidAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMyBidAccepted ? primaryGreen : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMyBidAccepted ? Icons.verified : Icons.lock_outline,
                        color: isMyBidAccepted ? primaryGreen : Colors.grey.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isMyBidAccepted
                              ? 'Your Bid Was Accepted! (Bidding Closed)'
                              : 'Bidding Closed • Contractor Proposal Accepted',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isMyBidAccepted ? primaryGreen : Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (hasMyBid) {
                final myBid = bids.firstWhere(
                  (b) => (_currentUserId != null && b.userId == _currentUserId) ||
                      (b.username != null && b.username!.contains('(You)')),
                );
                final canEdit = myBid.status.toLowerCase() == 'pending';

                actionButton = Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryGreen.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Bid: PKR ${_formatCurrency(myBid.bidPrice)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            Text(
                              'Status: ${myBid.status}',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        ElevatedButton.icon(
                          onPressed: () => _showBidDialog(context, project, existingBid: myBid),
                          icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                          label: Text(
                            'Edit Bid',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                );
              } else {
                actionButton = SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showBidDialog(context, project),
                    icon: const Icon(Icons.gavel_outlined, size: 18),
                    label: Text(
                      'PLACE YOUR BID',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  actionButton,
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Project Proposals & Bids',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _bidsFuture = _bidService.getBids(widget.projectId);
                          });
                          _fetchBidCount();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.refresh, size: 14, color: primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Refresh',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (bidSnapshot.connectionState == ConnectionState.waiting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2),
                      ),
                    )
                  else if (bids.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.gavel_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text(
                            'No Bids Submitted Yet',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Be the first contractor or buyer to place a proposal on this project.',
                            style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        return _buildUserBidCard(bids[idx], project, hasAcceptedBid);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserBidCard(Bid bid, Project project, bool hasAcceptedBid) {
    final isMyBid = (_currentUserId != null && bid.userId == _currentUserId) ||
        (bid.username != null && bid.username!.contains('(You)'));
    final canEdit = isMyBid && bid.status.toLowerCase() == 'pending' && !hasAcceptedBid;

    final rawName = (bid.username != null && bid.username!.trim().isNotEmpty)
        ? bid.username!.trim()
        : 'Contractor';
    final cleanName = rawName.replaceAll('(You)', '').trim();

    Color statusColor = Colors.orange.shade700;
    Color statusBg = Colors.orange.shade50;
    if (bid.status.toLowerCase() == 'accepted') {
      statusColor = primaryGreen;
      statusBg = const Color(0xFFE8F5E9);
    } else if (bid.status.toLowerCase() == 'rejected') {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMyBid ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyBid ? primaryGreen.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: isMyBid ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isMyBid ? primaryGreen : Colors.blueGrey.shade100,
                      child: Text(
                        cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          color: isMyBid ? Colors.white : Colors.blueGrey.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cleanName.isNotEmpty ? cleanName : 'Contractor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMyBid) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'YOUR BID',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (bid.ownerReply != null && bid.ownerReply!.isNotEmpty)
                            Text(
                              'Owner replied',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (canEdit) ...[
                InkWell(
                  onTap: () => _showBidDialog(context, project, existingBid: bid),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 12, color: primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bid.status,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Bid Offer: ',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'PKR ${_formatCurrency(bid.bidPrice)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          if (bid.bidDescription != null && bid.bidDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bid.bidDescription!,
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF475569), height: 1.4),
            ),
          ],
          if (bid.ownerReply != null && bid.ownerReply!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.reply, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Owner: ${bid.ownerReply!}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // INQUIRY SECTION
  // ==========================================
  Widget _buildInquirySection() {
    return Container(
      key: _inquiryKey,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Direct Project Inquiry',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Need pricing, floor plans, or booking details? Send an inquiry directly to the developer team.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Inquiry Type Chips
          Text(
            'I am inquiring as:',
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInquiryTypeChip('buyer', 'Buyer'),
              _buildInquiryTypeChip('agent', 'Real Estate Agent'),
              _buildInquiryTypeChip('investor', 'Investor'),
              _buildInquiryTypeChip('contractor', 'Contractor'),
              _buildInquiryTypeChip('other', 'Other'),
            ],
          ),

          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ask about available plots, payment schedule, or booking criteria...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please type your inquiry message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmittingInquiry ? null : _submitInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmittingInquiry
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'SEND INQUIRY',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
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
  }

  Widget _buildInquiryTypeChip(String key, String label) {
    final isSelected = _selectedInquiryType == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedInquiryType = selected ? key : null;
        });
      },
      selectedColor: primaryGreen,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : const Color(0xFF334155),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? primaryGreen : Colors.grey.shade300),
      ),
    );
  }

  // ==========================================
  // STICKY BOTTOM ACTION BAR
  // ==========================================
  Widget _buildBottomActionBar(BuildContext context, Project project) {
    final isOwner = _currentUserId != null && project.userId == _currentUserId;

    VoidCallback? onBidAction;
    IconData bidIcon;
    String bidLabel;
    Color buttonColor;
    Color textColor;
    Color borderColor;

    if (_isBiddingClosed) {
      bidIcon = Icons.lock_outline;
      bidLabel = 'Bidding Closed';
      textColor = Colors.grey.shade600;
      borderColor = Colors.grey.shade300;
      buttonColor = Colors.grey.shade100;
      onBidAction = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bidding for this project is closed as a proposal has already been accepted.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      };
    } else if (isOwner) {
      bidIcon = Icons.shield_outlined;
      bidLabel = 'Owner View';
      textColor = Colors.blue.shade700;
      borderColor = Colors.blue.shade200;
      buttonColor = Colors.blue.shade50;
      onBidAction = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot place a bid on your own project.'),
            backgroundColor: Colors.orange,
          ),
        );
      };
    } else if (_hasPlacedBid) {
      final canEdit = _currentUserBid != null && _currentUserBid!.status.toLowerCase() == 'pending';
      if (canEdit) {
        bidIcon = Icons.edit_outlined;
        bidLabel = 'Edit Bid';
        textColor = primaryGreen;
        borderColor = primaryGreen;
        buttonColor = const Color(0xFFF0FDF4);
        onBidAction = () => _showBidDialog(context, project, existingBid: _currentUserBid);
      } else {
        bidIcon = Icons.check_circle;
        bidLabel = 'Bid ${_currentUserBid?.status ?? "Placed"}';
        textColor = primaryGreen;
        borderColor = primaryGreen.withValues(alpha: 0.6);
        buttonColor = const Color(0xFFF0FDF4);
        onBidAction = () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your bid status is ${_currentUserBid?.status ?? "active"}.'),
              backgroundColor: primaryGreen,
            ),
          );
        };
      }
    } else {
      bidIcon = Icons.gavel;
      bidLabel = 'Place Bid';
      textColor = primaryGreen;
      borderColor = primaryGreen;
      buttonColor = Colors.white;
      onBidAction = () => _showBidDialog(context, project);
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Place / Edit Bid Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBidAction,
              icon: Icon(
                bidIcon,
                color: textColor,
                size: 18,
              ),
              label: Text(
                bidLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: borderColor,
                  width: 1.5,
                ),
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send Inquiry Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _scrollToInquiry,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 17),
              label: Text(
                'Inquire Now',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip({required IconData icon, required String label, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
