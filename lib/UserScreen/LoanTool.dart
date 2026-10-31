import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Model/ApplyLoanModel.dart';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:dhartti/service/ApplyLoanService.dart';
import 'package:dhartti/service/SchemeService.dart';
import 'package:dhartti/UserScreen/LoanDetailPage.dart';
import 'package:dhartti/Auth_Screens/login.dart';

class SchemesToolScreen extends StatefulWidget {
  const SchemesToolScreen({super.key});

  @override
  State<SchemesToolScreen> createState() => _SchemesToolScreenState();
}

class _SchemesToolScreenState extends State<SchemesToolScreen> {
  // Calculator state
  double _propertyPrice = 15000000; // 1.5 Crore default
  double _downPaymentPercent = 30; // 30% default
  double _loanYears = 20; // 20 years default
  String _selectedLoanType = 'All'; // 'All', 'Conventional', 'Islamic'

  late Future<List<Scheme>> _futureSchemes;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  final NumberFormat _pkrFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadSchemes();
  }

  void _loadSchemes() {
    setState(() {
      _futureSchemes = SchemeService.getAllSchemes();
    });
  }

  Future<void> _refreshSchemes() async {
    setState(() => _isRefreshing = true);
    try {
      final schemes = await SchemeService.getAllSchemes();
      setState(() {
        _futureSchemes = Future.value(schemes);
      });
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Formatting helpers
  String _formatPricePkr(double amount) {
    if (amount >= 10000000) {
      double crore = amount / 10000000;
      return '${crore.toStringAsFixed(2)} Crore';
    } else if (amount >= 100000) {
      double lakh = amount / 100000;
      return '${lakh.toStringAsFixed(2)} Lakh';
    } else {
      return _pkrFormat.format(amount);
    }
  }

  double get _downPaymentAmount => (_propertyPrice * _downPaymentPercent) / 100;
  double get _loanAmount => max(0.0, _propertyPrice - _downPaymentAmount);

  double _calculateEmi(double principal, double annualInterestRate, double years) {
    if (principal <= 0 || years <= 0) return 0;
    if (annualInterestRate <= 0) return principal / (years * 12);

    double monthlyRate = (annualInterestRate / 100) / 12;
    double n = years * 12;
    double emi = (principal * monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
    return emi.isNaN || emi.isInfinite ? 0 : emi;
  }

  void _openApplyModal(Scheme scheme, double calculatedEmi) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Sign In Required", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text("Please sign in or create an account to apply for financing and track your application status.", style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text("Sign In", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final savedName = prefs.getString('name') ?? '';
    final savedEmail = prefs.getString('email') ?? '';
    final savedNumber = prefs.getString('mobile_number') ?? prefs.getString('phone') ?? '';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApplyLoanBottomSheet(
        scheme: scheme,
        loanAmount: _loanAmount > 0 ? _loanAmount : (scheme.loanAmount ?? 0),
        estimatedEmi: calculatedEmi > 0 ? calculatedEmi : (scheme.monthlyInstallment ?? 0),
        initialName: savedName,
        initialEmail: savedEmail,
        initialNumber: savedNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF108224);
    final standardEmi = _calculateEmi(_loanAmount, 14.5, _loanYears);
    final totalPayment = (standardEmi * _loanYears * 12) + _downPaymentAmount;
    final totalMarkup = max(0.0, (standardEmi * _loanYears * 12) - _loanAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Schemes & Loan Calculator',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSchemes,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Interactive Loan Calculator Card ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
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
                              child: Icon(Icons.calculate_rounded, color: primaryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Home Loan Calculator',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Estimate your monthly EMI & financing cost',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Property Price Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Property Price',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatPricePkr(_propertyPrice),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: primaryColor,
                            thumbColor: primaryColor,
                            overlayColor: primaryColor.withOpacity(0.2),
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            value: _propertyPrice,
                            min: 1000000,
                            max: 50000000,
                            divisions: 98,
                            onChanged: (val) => setState(() => _propertyPrice = val),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10 Lakh', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                            Text('5 Crore', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Down Payment Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Down Payment (${_downPaymentPercent.toInt()}%)',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatPricePkr(_downPaymentAmount),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.blue.shade700,
                            thumbColor: Colors.blue.shade700,
                            overlayColor: Colors.blue.withOpacity(0.2),
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            value: _downPaymentPercent,
                            min: 10,
                            max: 90,
                            divisions: 16,
                            onChanged: (val) => setState(() => _downPaymentPercent = val),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                            Text('90%', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Loan Period Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Loan Tenure',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_loanYears.toInt()} Years (${(_loanYears * 12).toInt()} Mo)',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.purple.shade700,
                            thumbColor: Colors.purple.shade700,
                            overlayColor: Colors.purple.withOpacity(0.2),
                            inactiveTrackColor: Colors.grey.shade200,
                          ),
                          child: Slider(
                            value: _loanYears,
                            min: 1,
                            max: 30,
                            divisions: 29,
                            onChanged: (val) => setState(() => _loanYears = val),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1 Year', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                            Text('30 Years', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Estimated Result Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, const Color(0xFF0B5E1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ESTIMATED MONTHLY INSTALLMENT (EMI)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _pkrFormat.format(standardEmi),
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withOpacity(0.2), height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildResultMiniStat('Loan Required', _formatPricePkr(_loanAmount)),
                                  _buildResultMiniStat('Total Markup', _formatPricePkr(totalMarkup)),
                                  _buildResultMiniStat('Total Payable', _formatPricePkr(totalPayment)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Filter Tabs for Schemes ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Loan Schemes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLoanType,
                            isDense: true,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Types')),
                              DropdownMenuItem(value: 'Conventional', child: Text('Conventional')),
                              DropdownMenuItem(value: 'Islamic', child: Text('Islamic')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLoanType = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search schemes by bank or name...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Schemes List
                  FutureBuilder<List<Scheme>>(
                    future: _futureSchemes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Could not load loan schemes',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                snapshot.error.toString(),
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: _loadSchemes,
                                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }

                      final allSchemes = snapshot.data ?? [];
                      final filtered = allSchemes.where((s) {
                        final name = (s.schemeName ?? '').toLowerCase();
                        final type = (s.loanType ?? '').toLowerCase();
                        final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || type.contains(_searchQuery);
                        final matchesType = _selectedLoanType == 'All' ||
                            type.contains(_selectedLoanType.toLowerCase());
                        return matchesSearch && matchesType;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No schemes found',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try adjusting your search query or loan type filter.',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final scheme = filtered[index];
                          final schemeInterest = scheme.interestRate ?? 14.5;
                          final schemeCalculatedEmi = _calculateEmi(_loanAmount, schemeInterest, _loanYears);

                          return _buildSchemeComparisonCard(
                            scheme: scheme,
                            calculatedEmi: schemeCalculatedEmi,
                            primaryColor: primaryColor,
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
    );
  }

  Widget _buildResultMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSchemeComparisonCard({
    required Scheme scheme,
    required double calculatedEmi,
    required Color primaryColor,
  }) {
    final isIslamic = (scheme.loanType ?? '').toLowerCase().contains('islamic');

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scheme.schemeName ?? 'Housing Loan Scheme',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isIslamic ? Colors.teal.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              scheme.loanType ?? 'Conventional',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isIslamic ? Colors.teal.shade800 : Colors.blue.shade800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.percent_rounded, size: 12, color: primaryColor),
                                const SizedBox(width: 3),
                                Text(
                                  '${scheme.interestRate?.toStringAsFixed(1) ?? '14.5'}% Markup',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monthly Installment',
                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      Text(
                        _pkrFormat.format(calculatedEmi > 0 ? calculatedEmi : (scheme.monthlyInstallment ?? 0)),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Details row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardDetailCol('Max Loan Limit', _formatPricePkr(scheme.loanAmount ?? 0)),
                _buildCardDetailCol('Required Income', 'PKR ${scheme.monthlyInstallment != null ? _formatPricePkr(scheme.monthlyInstallment! * 2) : 'Open'}'),
                _buildCardDetailCol('Tenure', '${_loanYears.toInt()} Years'),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchemeDetailScreen(schemeId: scheme.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openApplyModal(scheme, calculatedEmi),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Apply Now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildCardDetailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Smooth Modal Bottom Sheet for Instant Loan Apply
// ----------------------------------------------------
class _ApplyLoanBottomSheet extends StatefulWidget {
  final Scheme scheme;
  final double loanAmount;
  final double estimatedEmi;
  final String initialName;
  final String initialEmail;
  final String initialNumber;

  const _ApplyLoanBottomSheet({
    required this.scheme,
    required this.loanAmount,
    required this.estimatedEmi,
    required this.initialName,
    required this.initialEmail,
    required this.initialNumber,
  });

  @override
  State<_ApplyLoanBottomSheet> createState() => _ApplyLoanBottomSheetState();
}

class _ApplyLoanBottomSheetState extends State<_ApplyLoanBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _numberController;
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Lahore');
  final TextEditingController _salaryController = TextEditingController(text: '150000');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _numberController = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final app = ApplyLoan(
        id: 0,
        userId: 0,
        loanId: widget.scheme.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        number: _numberController.text.trim(),
        cnic: _cnicController.text.trim(),
        city: _cityController.text.trim(),
        salary: double.tryParse(_salaryController.text.trim()) ?? 0,
      );

      await ApplyLoanService.applyForLoan(app);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your loan application was submitted successfully! The scheme manager will reach out shortly.'),
            backgroundColor: Color(0xFF108224),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission notice: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFF108224),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const primaryColor = Color(0xFF108224);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply for Loan Scheme',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          widget.scheme.schemeName ?? '',
                          style: GoogleFonts.poppins(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildField('Full Name', _nameController, Icons.person_outline, (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _buildField('Email Address', _emailController, Icons.email_outlined, (v) => v == null || !v.contains('@') ? 'Valid email required' : null, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildField('Phone / WhatsApp', _numberController, Icons.phone_outlined, (v) => v == null || v.length < 10 ? 'Valid phone number required' : null, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('CNIC (National ID)', _cnicController, Icons.badge_outlined, (v) => v == null || v.isEmpty ? 'Required' : null, hint: 'e.g. 35201-1234567-1'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField('City', _cityController, Icons.location_city_outlined, (v) => v == null || v.isEmpty ? 'Required' : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField('Monthly Income', _salaryController, Icons.payments_outlined, (v) => v == null || v.isEmpty ? 'Required' : null, keyboardType: TextInputType.number),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Submit Loan Application',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF108224), width: 1.5),
        ),
      ),
    );
  }
}
