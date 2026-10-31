import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:dhartti/UserScreen/LoanDetailPage.dart' as loan_page;
import 'package:dhartti/UserScreen/LoanTool/add.dart';

class SchemeDetailScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailScreen({super.key, required this.scheme});

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  late Scheme _currentScheme;
  bool _isOwner = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _currentScheme = widget.scheme;
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final myUserId = prefs.get('userId')?.toString() ?? prefs.get('user_id')?.toString();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isOwner = myUserId != null &&
            widget.scheme.userId.toString() == myUserId;
      });
    }
  }

  static const Color primaryGreen = Color(0xFF108224);

  String _formatPKR(num? amount) {
    if (amount == null) return 'PKR 0';
    final val = amount.toDouble();
    if (val >= 10000000) {
      return 'PKR ${(val / 10000000).toStringAsFixed(2)} Crore';
    } else if (val >= 100000) {
      return 'PKR ${(val / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return 'PKR ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  String _formatExactNumber(num? amount) {
    if (amount == null) return '0';
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _currentScheme;
    final propertyVal = s.propertyValue ?? 0;
    final downPay = s.downPayment ?? 0;
    final loanAmt = s.loanAmount ?? (propertyVal - downPay);
    final downPercent = propertyVal > 0 ? ((downPay / propertyVal) * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(
          'Scheme Details',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Scheme',
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditSchemeScreen(scheme: _currentScheme),
                  ),
                );
                if (updated == true) {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF108224), Color(0xFF0B631B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.schemeName ?? 'Financing Scheme',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.loanType ?? 'General Loan',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: s.employmentStatus
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.amber.shade900.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.employmentStatus ? 'Employed' : 'Flexible Eligibility',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
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
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTIMATED MONTHLY INSTALLMENT',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPKR(s.monthlyInstallment),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${s.interestRate ?? 0}% p.a.',
                          style: GoogleFonts.poppins(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Financial Breakdown Card
            Text(
              'Financial Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMetricTile(
                    icon: Icons.home_work_outlined,
                    label: 'Total Property Value',
                    formattedValue: _formatPKR(propertyVal),
                    exactValue: 'PKR ${_formatExactNumber(propertyVal)}',
                    color: Colors.blue.shade700,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Down Payment ($downPercent%)',
                    formattedValue: _formatPKR(downPay),
                    exactValue: 'PKR ${_formatExactNumber(downPay)}',
                    color: Colors.amber.shade800,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMetricTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Financed Loan Amount',
                    formattedValue: _formatPKR(loanAmt),
                    exactValue: 'PKR ${_formatExactNumber(loanAmt)}',
                    color: primaryGreen,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMetricTile(
                    icon: Icons.percent_outlined,
                    label: 'Annual Interest Rate',
                    formattedValue: '${s.interestRate ?? 0}%',
                    exactValue: 'Standard Annualized Markup Rate',
                    color: Colors.purple.shade700,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scheme Policy & Requirements
            Text(
              'Terms & Eligibility',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPolicyRow(
                    icon: Icons.badge_outlined,
                    title: 'Employment Requirement',
                    desc: s.employmentStatus
                        ? 'Valid proof of employment or salaried bank statement required.'
                        : 'Open to self-employed and flexible income applicants.',
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Transparent Pricing',
                    desc: 'No hidden processing fees. All down payment and markup terms are locked as per agreement.',
                  ),
                  const SizedBox(height: 14),
                  _buildPolicyRow(
                    icon: Icons.shield_outlined,
                    title: 'Dhartti Verified Protection',
                    desc: 'Transactions and documentation adhere to verified national housing finance guidelines.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_isOwner) {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditSchemeScreen(scheme: _currentScheme),
                          ),
                        );
                        if (updated == true) {
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        }
                      } else {
                        if (!_isLoggedIn) {
                          _showLoginRequiredDialog();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => loan_page.SchemeDetailScreen(schemeId: _currentScheme.id),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(_isOwner ? Icons.edit : Icons.send_rounded, size: 18),
                    label: Text(
                      _isOwner ? 'Edit Scheme' : 'Apply for Financing',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Sign In Required",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Please sign in or create an account to apply for this financing scheme.",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) => _checkOwnership());
            },
            child: const Text("Sign In", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String formattedValue,
    required String exactValue,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
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
                  formattedValue,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  exactValue,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
