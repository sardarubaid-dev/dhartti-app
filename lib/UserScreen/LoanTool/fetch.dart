import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Auth_Screens/register.dart';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:dhartti/service/SchemeService.dart';
import 'package:dhartti/UserScreen/LoanTool/add.dart';
import 'package:dhartti/UserScreen/LoanTool/scheme_detail_screen.dart';
import 'package:dhartti/UserScreen/LoanTool/SchemeApplicationsScreen.dart';

class SchemeListScreen extends StatefulWidget {
  final bool showUserSchemesOnly;

  const SchemeListScreen({super.key, this.showUserSchemesOnly = true});

  @override
  _SchemeListScreenState createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends State<SchemeListScreen> {
  late Future<List<Scheme>> _futureSchemes;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedLoanType = 'All';
  bool _isDeleting = false;
  bool _isGuest = false;

  static const Color primaryColor = Color(0xFF108224);

  final List<String> _loanTypes = [
    'All',
    'Home Loan',
    'Business Loan',
    'Personal Loan',
    'Education Loan',
    'Car Loan'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showUserSchemesOnly) {
      _checkAuthAndLoad();
    } else {
      _loadSchemes();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _checkAuthAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
        });
      }
      return;
    }
    setState(() {
      _isGuest = false;
    });
    _loadSchemes();
  }

  void _loadSchemes() {
    setState(() {
      _futureSchemes = widget.showUserSchemesOnly
          ? SchemeService.getUserSchemes()
          : SchemeService.getAllSchemes();
    });
  }

  String _formatCurrency(dynamic val, {bool isMonthly = false}) {
    if (val == null) return "PKR 0";
    double numVal = 0.0;
    if (val is num) {
      numVal = val.toDouble();
    } else {
      final clean = val.toString().replaceAll(',', '').replaceAll('PKR', '').replaceAll('Rs', '').replaceAll('\$', '').trim();
      numVal = double.tryParse(clean) ?? 0.0;
    }
    if (numVal <= 0) return "PKR 0";

    final suffix = isMonthly ? " / mo" : "";

    if (numVal >= 10000000) {
      double crore = numVal / 10000000;
      String formatted = crore.toStringAsFixed(crore.truncateToDouble() == crore ? 0 : 2);
      return "PKR $formatted Crore$suffix";
    } else if (numVal >= 100000) {
      double lac = numVal / 100000;
      String formatted = lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2);
      return "PKR $formatted Lakh$suffix";
    } else {
      final intVal = numVal.toInt();
      final str = intVal.toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
      return "PKR $formatted$suffix";
    }
  }

  List<Scheme> _getFilteredSchemes(List<Scheme> schemes) {
    return schemes.where((scheme) {
      // Loan Type filter
      if (_selectedLoanType != 'All') {
        final type = (scheme.loanType ?? '').toLowerCase();
        if (!type.contains(_selectedLoanType.toLowerCase())) return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final name = (scheme.schemeName ?? '').toLowerCase();
        final type = (scheme.loanType ?? '').toLowerCase();
        final match = name.contains(_searchQuery) || type.contains(_searchQuery);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _deleteScheme(int schemeId, String? name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            const Text('Delete Scheme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this financing scheme?',
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
                name?.isNotEmpty == true ? name! : 'Untitled Scheme',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone and will remove it from all listings.',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await SchemeService.deleteScheme(schemeId);
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Scheme deleted successfully'),
                ],
              ),
              backgroundColor: primaryColor,
            ),
          );
          _loadSchemes();
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

  void _navigateToAddEditScreen({Scheme? scheme}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditSchemeScreen(scheme: scheme),
      ),
    );

    if (result == true) {
      _loadSchemes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.showUserSchemesOnly ? 'My Financing Schemes' : 'Available Schemes',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          if (widget.showUserSchemesOnly && !_isGuest)
            IconButton(
              icon: const Icon(Icons.people_alt_rounded, color: primaryColor),
              tooltip: 'Scheme Applications',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            tooltip: 'Refresh',
            onPressed: () {
              if (widget.showUserSchemesOnly) {
                _checkAuthAndLoad();
              } else {
                _loadSchemes();
              }
            },
          ),
        ],
      ),
      floatingActionButton: (widget.showUserSchemesOnly && !_isGuest)
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddEditScreen(),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Scheme', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isGuest
          ? _buildGuestState()
          : Stack(
        children: [
          RefreshIndicator(
            color: primaryColor,
            onRefresh: () async => _loadSchemes(),
            child: FutureBuilder<List<Scheme>>(
              future: _futureSchemes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isSearch: false);
                }

                final all = snapshot.data!;
                final filtered = _getFilteredSchemes(all);

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Filter & Search Area
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total count badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Schemes (${filtered.length} of ${all.length})',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${all.length} Total',
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
                                hintText: 'Search schemes by name or type...',
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
                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _loanTypes.map((type) {
                                  final isSelected = _selectedLoanType == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setState(() => _selectedLoanType = type);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? primaryColor : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.grey.shade800,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 12.5,
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
                    ),

                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(isSearch: true),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final scheme = filtered[index];
                              return _buildSchemeCard(scheme);
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
                        Text('Deleting scheme...', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildSchemeCard(Scheme scheme) {
    final loanType = scheme.loanType ?? 'Financing';
    final isHome = loanType.toLowerCase().contains('home');
    final typeColor = isHome ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);

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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SchemeDetailScreen(scheme: scheme)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title & Loan Type badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        scheme.schemeName?.isNotEmpty == true ? scheme.schemeName! : 'Financing Scheme',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        loanType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Highlighted Monthly Installment Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_outlined, color: primaryColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Installment',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatCurrency(scheme.monthlyInstallment, isMonthly: true),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Interest Rate Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              '${scheme.interestRate?.toString() ?? '0'}% p.a.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Financial Specs Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCol(
                        'Property Value',
                        _formatCurrency(scheme.propertyValue),
                        Icons.home_work_outlined,
                      ),
                    ),
                    Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildSpecCol(
                        'Down Payment',
                        _formatCurrency(scheme.downPayment),
                        Icons.savings_outlined,
                      ),
                    ),
                    Container(height: 30, width: 1, color: const Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildSpecCol(
                        'Loan Amount',
                        _formatCurrency(scheme.loanAmount),
                        Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom Divider & Actions
                if (widget.showUserSchemesOnly) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Applications Button
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SchemeApplicationsScreen(
                              specificSchemeId: scheme.id,
                              specificSchemeName: scheme.schemeName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.people_alt_outlined, size: 15, color: Colors.white),
                        label: Text(
                          scheme.applicationsCount > 0 ? '${scheme.applicationsCount} Apps' : 'Apps',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Edit Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToAddEditScreen(scheme: scheme),
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete Button
                      OutlinedButton(
                        onPressed: () => _deleteScheme(scheme.id, scheme.schemeName),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          backgroundColor: Colors.red.shade50.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isSearch}) {
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
                isSearch ? Icons.search_off_rounded : Icons.account_balance_wallet_outlined,
                size: 54,
                color: isSearch ? Colors.orange.shade700 : primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? 'No Matching Schemes Found' : 'No Financing Schemes Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try adjusting your search query or loan type filter.'
                  : 'Create flexible loan and installment schemes to attract buyers for your properties and construction projects.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isSearch)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedLoanType = 'All');
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
            else if (widget.showUserSchemesOnly)
              ElevatedButton.icon(
                onPressed: () => _navigateToAddEditScreen(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Your First Scheme', style: TextStyle(fontWeight: FontWeight.bold)),
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
              'Error Loading Schemes',
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
              onPressed: _loadSchemes,
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
                Icons.lock_outline_rounded,
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
              'You need to be logged into your Dhartti seller account to view and manage your financing schemes.',
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
                  ).then((_) => _checkAuthAndLoad());
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
                ).then((_) => _checkAuthAndLoad());
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
