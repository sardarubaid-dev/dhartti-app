import 'package:dhartti/Model/ApplyLoanModel.dart';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:dhartti/service/ApplyLoanService.dart';
import 'package:dhartti/service/SchemeService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchemeDetailScreen extends StatefulWidget {
  final int schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  late Future<Map<String, dynamic>> _futureDetails;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

  // Application form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Lahore');
  final TextEditingController _salaryController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _futureDetails = SchemeService.getSchemeDetails(widget.schemeId);
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('mobile_number') ?? prefs.getString('phone') ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _cityController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication(Scheme scheme) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final application = ApplyLoan(
        id: 0,
        userId: 0,
        loanId: scheme.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        number: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
        city: _cityController.text.trim(),
        salary: double.tryParse(_salaryController.text.trim()) ?? 0,
      );

      await ApplyLoanService.applyForLoan(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your loan application was submitted successfully!'),
            backgroundColor: Color(0xFF108224),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _cnicController.clear();
        _salaryController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFF108224),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF108224);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Scheme Details',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 14),
                    Text(
                      'Failed to load scheme details',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: () => setState(() {
                        _futureDetails = SchemeService.getSchemeDetails(widget.schemeId);
                      }),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!['scheme'] == null) {
            return Center(
              child: Text(
                'Scheme not found',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            );
          }

          final scheme = Scheme.fromJson(snapshot.data!['scheme']);
          final relatedList = snapshot.data!['related_schemes'] as List? ?? [];
          final relatedSchemes = relatedList.map((j) => Scheme.fromJson(j)).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scheme Overview Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  scheme.schemeName ?? 'Housing Scheme',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scheme.loanType ?? 'Conventional',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade200, height: 1),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildStatCol('Maximum Loan Amount', _currencyFormat.format(scheme.loanAmount ?? 0), Icons.monetization_on_outlined, primaryColor),
                              _buildStatCol('Annual Markup / Interest', '${scheme.interestRate?.toStringAsFixed(1) ?? '14.5'}% p.a.', Icons.percent_rounded, Colors.orange.shade800),
                              _buildStatCol('Monthly Payment', _currencyFormat.format(scheme.monthlyInstallment ?? 0), Icons.calendar_month_outlined, Colors.blue.shade800),
                              _buildStatCol('Eligibility Criteria', scheme.employmentStatus ? 'Salaried & Business' : 'Open for All', Icons.work_outline_rounded, Colors.purple.shade800),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Financial Details Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_outlined, size: 20, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Financial Terms & Conditions',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Estimated Property Value', _currencyFormat.format(scheme.propertyValue ?? 0)),
                          _buildDetailRow('Required Down Payment', _currencyFormat.format(scheme.downPayment ?? 0)),
                          _buildDetailRow(
                            'Financing Ratio (LTV)',
                            '${(((scheme.loanAmount ?? 0) / (scheme.propertyValue ?? 1)) * 100).toStringAsFixed(1)}%',
                          ),
                          _buildDetailRow('Application Status', 'Active & Accepting Applicants'),
                          if (scheme.createdAt != null)
                            _buildDetailRow('Published Date', DateFormat('dd MMM yyyy').format(scheme.createdAt!)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // In-Place Application Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.send_rounded, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Apply for this Scheme',
                                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Our loan officer will contact you within 24 hours',
                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInput('Full Name', _nameController, Icons.person_outline, (v) => v == null || v.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            _buildInput('Email Address', _emailController, Icons.email_outlined, (v) => v == null || !v.contains('@') ? 'Valid email required' : null, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 12),
                            _buildInput('Phone / WhatsApp', _phoneController, Icons.phone_outlined, (v) => v == null || v.length < 10 ? 'Valid phone required' : null, keyboardType: TextInputType.phone),
                            const SizedBox(height: 12),
                            _buildInput('CNIC (National ID)', _cnicController, Icons.badge_outlined, (v) => v == null || v.isEmpty ? 'Required' : null, hint: 'e.g. 35201-1234567-1'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildInput('City', _cityController, Icons.location_city_outlined, (v) => v == null || v.isEmpty ? 'Required' : null)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildInput('Monthly Salary (PKR)', _salaryController, Icons.payments_outlined, (v) => v == null || v.isEmpty ? 'Required' : null, keyboardType: TextInputType.number)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submitApplication(scheme),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      'Submit Application Now',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (relatedSchemes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'More Loan Schemes You Might Like',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: relatedSchemes.length > 3 ? 3 : relatedSchemes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final rel = relatedSchemes[idx];
                          return InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SchemeDetailScreen(schemeId: rel.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rel.schemeName ?? '',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${rel.interestRate?.toStringAsFixed(1) ?? '14.5'}% Markup • ${rel.loanType ?? ''}',
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
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInput(
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
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF108224), width: 1.5)),
      ),
    );
  }
}
