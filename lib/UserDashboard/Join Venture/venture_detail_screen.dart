import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhartti/Model/joinVenture.dart';
import 'package:dhartti/Model/join_venture_bid_model.dart';
import 'package:dhartti/service/join_venture_service.dart';
import 'package:dhartti/service/seller_service.dart';

class VentureDetailScreen extends StatefulWidget {
  final JoinVenture venture;

  const VentureDetailScreen({Key? key, required this.venture}) : super(key: key);

  @override
  State<VentureDetailScreen> createState() => _VentureDetailScreenState();
}

class _VentureDetailScreenState extends State<VentureDetailScreen> {
  final JoinVentureService _ventureService = JoinVentureService();
  final SellerService _sellerService = SellerService();
  
  late Future<List<JoinVentureBid>> _bidsFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);
  
  int? _currentUserId;
  bool _isOwner = false;
  bool _hasAcceptedBid = false;
  JoinVentureBid? _myBid;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color darkGreen = Color(0xFF0A5C19);
  static const Color mintBg = Color(0xFFF6FAF7);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadBids();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic raw = prefs.get('userId');
      final int? uid = raw is int ? raw : (raw is String ? int.tryParse(raw) : null);
      if (mounted) {
        setState(() {
          _currentUserId = uid;
          _isOwner = (uid != null && uid == widget.venture.userId);
        });
      }
    } catch (_) {}
  }

  void _loadBids() {
    setState(() {
      _bidsFuture = _ventureService.getVentureBids(widget.venture.id).then((bids) {
        if (mounted) {
          final accepted = bids.any((b) => b.status.toLowerCase() == 'accepted');
          JoinVentureBid? mine;
          try {
            mine = bids.firstWhere((b) => b.isMine || (_currentUserId != null && b.userId == _currentUserId));
          } catch (_) {
            mine = null;
          }
          setState(() {
            _hasAcceptedBid = accepted;
            _myBid = mine;
          });
        }
        return bids;
      });
    });
  }

  Future<void> _launchContact(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch contact method', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: isError ? Colors.red.shade700 : dharttiGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Responsive Bottom Sheet for Bidding / Proposal
  void _showBidBottomSheet({JoinVentureBid? existingBid}) {
    final bool isEditing = existingBid != null;
    String initialAmount = '';
    if (isEditing && existingBid.amount != null) {
      final parsed = double.tryParse(existingBid.amount!.replaceAll(',', '').trim());
      if (parsed != null && parsed > 0) {
        initialAmount = parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
      } else {
        initialAmount = existingBid.amount!;
      }
    }
    final amountController = TextEditingController(text: initialAmount);
    final messageController = TextEditingController(text: isEditing ? (existingBid.message ?? '') : '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: dharttiGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isEditing ? Icons.edit_note_rounded : Icons.handshake_rounded, color: dharttiGreen, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? 'Edit Venture Proposal' : 'Submit Venture Proposal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    isEditing ? 'Update your proposed investment share or pitch.' : widget.venture.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Proposed Investment Amount
                        Text(
                          'Proposed Investment Amount (PKR)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Text(
                                'PKR',
                                style: GoogleFonts.poppins(
                                  color: dharttiGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            hintText: 'e.g. 2,500,000',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: dharttiGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter proposed investment amount';
                            }
                            final clean = value.replaceAll(',', '').replaceAll(' ', '');
                            final num? n = num.tryParse(clean);
                            if (n == null || n <= 0) {
                              return 'Please enter a valid amount greater than 0';
                            }
                            return null;
                          },
                        ),

                        // Quick Chips
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildQuickChip('+ 500K', '500000', amountController, setModalState),
                            _buildQuickChip('+ 1M', '1000000', amountController, setModalState),
                            _buildQuickChip('+ 2.5M', '2500000', amountController, setModalState),
                            _buildQuickChip('+ 5M', '5000000', amountController, setModalState),
                            _buildQuickChip('+ 10M', '10000000', amountController, setModalState),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Proposal Pitch / Note
                        Text(
                          'Partnership Pitch / Proposal Note',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: messageController,
                          maxLines: 3,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Describe your expertise, capital share, or timeline...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: dharttiGreen, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    FocusScope.of(context).unfocus();
                                    setModalState(() => isSubmitting = true);

                                    try {
                                      final rawAmount = amountController.text.replaceAll(',', '').trim();
                                      if (isEditing) {
                                        await _ventureService.updateBid(
                                          ventureId: widget.venture.id,
                                          bidId: existingBid.id,
                                          amount: rawAmount,
                                          message: messageController.text.trim().isNotEmpty
                                              ? messageController.text.trim()
                                              : null,
                                        );
                                        if (bottomSheetContext.mounted) {
                                          Navigator.pop(bottomSheetContext);
                                        }
                                        _showSnackBar('Proposal updated successfully!');
                                        _loadBids();
                                      } else {
                                        await _ventureService.placeBid(
                                          ventureId: widget.venture.id,
                                          amount: rawAmount,
                                          message: messageController.text.trim().isNotEmpty
                                              ? messageController.text.trim()
                                              : null,
                                        );
                                        if (bottomSheetContext.mounted) {
                                          Navigator.pop(bottomSheetContext);
                                        }
                                        _showSnackBar('Proposal submitted successfully! The creator will review it.');
                                        _loadBids();
                                      }
                                    } catch (e) {
                                      setModalState(() => isSubmitting = false);
                                      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dharttiGreen,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isEditing ? Icons.check_circle_outline : Icons.send_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing ? 'Update Proposal' : 'Submit Proposal',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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
      },
    );
  }

  Widget _buildQuickChip(String label, String value, TextEditingController controller, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        setModalState(() {
          final cur = double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
          final add = double.tryParse(value) ?? 0;
          final total = (cur == 0 ? add : cur + add).toInt();
          controller.text = total.toString();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: mintBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dharttiGreen.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: darkGreen,
          ),
        ),
      ),
    );
  }

  // Owner Response Dialog (Accept / Reject)
  void _respondToVentureBid(JoinVentureBid bid, String targetStatus) {
    final TextEditingController replyController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                targetStatus == 'Accepted' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: targetStatus == 'Accepted' ? dharttiGreen : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '$targetStatus Proposal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: targetStatus == 'Accepted' ? dharttiGreen : Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this proposal as $targetStatus?',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: replyController,
                maxLines: 2,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Message to Partner (Optional)',
                  hintText: 'e.g. Let\'s schedule an agreement call...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: targetStatus == 'Accepted' ? dharttiGreen : Colors.red,
                      width: 1.5,
                    ),
                  ),
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
                      final res = await _sellerService.updateVentureBidStatus(
                        bid.id,
                        targetStatus,
                        ownerReply: replyController.text.trim().isNotEmpty ? replyController.text.trim() : null,
                      );
                      setDialogState(() => isSubmitting = false);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      if (mounted) {
                        _showSnackBar(
                          res['message'] ?? 'Proposal updated successfully',
                          isError: res['success'] != true,
                        );
                        if (res['success'] == true) {
                          _loadBids();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: targetStatus == 'Accepted' ? dharttiGreen : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirm $targetStatus', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venture = widget.venture;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          'Venture Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: dharttiGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Bids',
            onPressed: _loadBids,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBids(),
        color: dharttiGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Card
              _buildHeroCard(venture),

              const SizedBox(height: 16),

              // Overview Stats Grid
              _buildStatsGrid(venture),

              const SizedBox(height: 16),

              // Description Section
              _buildDescriptionCard(venture),

              const SizedBox(height: 16),

              // Creator Profile Card
              _buildCreatorCard(venture),

              const SizedBox(height: 24),

              // Proposals / Bids Header
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: dharttiGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Partnership Proposals',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_hasAcceptedBid) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Closed',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!_isOwner) ...[
                    const SizedBox(width: 8),
                    if (_myBid != null && _myBid!.status.toLowerCase() == 'pending')
                      InkWell(
                        onTap: () => _showBidBottomSheet(existingBid: _myBid),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: dharttiGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dharttiGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 14, color: dharttiGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Edit Proposal',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: dharttiGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_myBid == null)
                      InkWell(
                        onTap: () => _showBidBottomSheet(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: dharttiGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, size: 16, color: dharttiGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Propose',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: dharttiGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Bids List
              _buildBidsList(),
            ],
          ),
        ),
      ),

      // Bottom Floating CTA Bar (for non-owners)
      bottomNavigationBar: (!_isOwner)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 50,
                  child: Builder(
                    builder: (context) {
                      if (_hasAcceptedBid) {
                        final isMineAccepted = _myBid != null && _myBid!.status.toLowerCase() == 'accepted';
                        return Container(
                          decoration: BoxDecoration(
                            color: isMineAccepted ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMineAccepted ? dharttiGreen : Colors.grey.shade300,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isMineAccepted ? Icons.verified : Icons.lock_outline,
                                color: isMineAccepted ? dharttiGreen : Colors.grey.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isMineAccepted
                                      ? 'Your Proposal Was Accepted!'
                                      : 'Venture Closed • Partner Selected',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isMineAccepted ? dharttiGreen : Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_myBid != null) {
                        final isPending = _myBid!.status.toLowerCase() == 'pending';
                        if (isPending) {
                          return OutlinedButton.icon(
                            onPressed: () => _showBidBottomSheet(existingBid: _myBid),
                            icon: const Icon(Icons.edit_note_rounded, color: dharttiGreen, size: 20),
                            label: Text(
                              'Edit Your Proposal',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: dharttiGreen,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: dharttiGreen, width: 1.5),
                              backgroundColor: const Color(0xFFF0FDF4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: dharttiGreen, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Proposal Placed (${_myBid!.status})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: dharttiGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }

                      return ElevatedButton.icon(
                        onPressed: () => _showBidBottomSheet(),
                        icon: const Icon(Icons.handshake_rounded, color: Colors.white),
                        label: Text(
                          'Submit Investment Proposal',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dharttiGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // Hero Card
  Widget _buildHeroCard(JoinVenture venture) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6E20), Color(0xFF108224), Color(0xFF1C9E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: dharttiGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle motif icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.apartment_rounded,
              size: 140,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Industry badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        venture.industry.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  venture.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                // Location row
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        venture.location ?? 'Pakistan (Flexible)',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
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
    );
  }

  // Stats Grid
  Widget _buildStatsGrid(JoinVenture venture) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.business_center_rounded,
            title: 'Sector',
            value: venture.industry,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            icon: Icons.calendar_today_rounded,
            title: 'Posted',
            value: DateFormat('dd MMM yyyy').format(venture.createdAt),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            icon: Icons.groups_rounded,
            title: 'Proposals',
            value: '${venture.bidsCount} Active',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dharttiGreen, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Description Card
  Widget _buildDescriptionCard(JoinVenture venture) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              const Icon(Icons.description_outlined, color: dharttiGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Venture Overview',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            venture.description,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Creator Card
  Widget _buildCreatorCard(JoinVenture venture) {
    final creatorName = venture.user?.name ?? 'Creator';
    final creatorEmail = venture.user?.email ?? '';
    final creatorPhone = venture.user?.contactNumber ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: dharttiGreen.withOpacity(0.12),
            child: Text(
              creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'U',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: dharttiGreen,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        creatorName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 16, color: dharttiGreen),
                  ],
                ),
                Text(
                  _isOwner ? 'You are the creator' : 'Venture Initiator',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _isOwner ? dharttiGreen : Colors.grey.shade500,
                    fontWeight: _isOwner ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (!_isOwner && (creatorPhone.isNotEmpty || creatorEmail.isNotEmpty)) ...[
            if (creatorPhone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: dharttiGreen, size: 20),
                onPressed: () => _launchContact('tel:$creatorPhone'),
                tooltip: 'Call Initiator',
              ),
            if (creatorEmail.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.email_outlined, color: dharttiGreen, size: 20),
                onPressed: () => _launchContact('mailto:$creatorEmail'),
                tooltip: 'Email Initiator',
              ),
          ],
        ],
      ),
    );
  }

  // Bids / Proposals List
  Widget _buildBidsList() {
    return FutureBuilder<List<JoinVentureBid>>(
      future: _bidsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: dharttiGreen, strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
                const SizedBox(height: 10),
                Text(
                  'Failed to load proposals',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _loadBids,
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: Text('Retry', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: dharttiGreen),
                ),
              ],
            ),
          );
        }

        final bids = snapshot.data ?? [];

        if (bids.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.volunteer_activism_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No proposals received yet',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isOwner
                      ? 'Proposals from prospective partners will show up here.'
                      : 'Be the first partner to propose an investment share!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (!_isOwner) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showBidBottomSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dharttiGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Submit First Proposal', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bid = bids[index];
            return _buildBidCard(bid);
          },
        );
      },
    );
  }

  // Proposal Card
  Widget _buildBidCard(JoinVentureBid bid) {
    final isMine = bid.isMine || (_currentUserId != null && bid.userId == _currentUserId);
    final status = bid.status.toLowerCase();
    final isAccepted = status == 'accepted';
    final isRejected = status == 'rejected';
    final isPending = !isAccepted && !isRejected;

    Color statusColor = Colors.amber.shade800;
    Color statusBg = Colors.amber.shade50;
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (isAccepted) {
      statusColor = dharttiGreen;
      statusBg = const Color(0xFFE8F5E9);
      statusIcon = Icons.check_circle_rounded;
    } else if (isRejected) {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
      statusIcon = Icons.cancel_rounded;
    }

    final double amountVal = double.tryParse(bid.amount ?? '0') ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMine ? dharttiGreen.withOpacity(0.5) : Colors.grey.shade200,
          width: isMine ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar, Name, Amount & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isMine ? dharttiGreen : Colors.grey.shade200,
                child: Text(
                  bid.bidderName.isNotEmpty ? bid.bidderName[0].toUpperCase() : 'P',
                  style: GoogleFonts.poppins(
                    color: isMine ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bid.bidderName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: dharttiGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'You',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: dharttiGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(bid.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountVal > 0 ? _currencyFormat.format(amountVal) : 'Negotiable',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMine && isPending && !_hasAcceptedBid) ...[
                        InkWell(
                          onTap: () => _showBidBottomSheet(existingBid: bid),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: dharttiGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: dharttiGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 12, color: dharttiGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    color: dharttiGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
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
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              bid.status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Proposal Pitch Message
          if (bid.message != null && bid.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                bid.message!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Owner Reply if present
          if (bid.ownerReply != null && bid.ownerReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dharttiGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: dharttiGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 14, color: dharttiGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Creator Response:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: dharttiGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bid.ownerReply!,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],

          // Owner Action Controls (Accept / Reject)
          if (_isOwner && isPending && !_hasAcceptedBid) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _respondToVentureBid(bid, 'Rejected'),
                  icon: const Icon(Icons.close_rounded, size: 15, color: Colors.red),
                  label: Text('Reject', style: GoogleFonts.poppins(color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _respondToVentureBid(bid, 'Accepted'),
                  icon: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  label: Text('Accept', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    elevation: 0,
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
