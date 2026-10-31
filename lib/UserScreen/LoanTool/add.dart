import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Model/SchemeModel.dart';
import 'package:dhartti/service/SchemeService.dart';

class AddEditSchemeScreen extends StatefulWidget {
  final Scheme? scheme;

  const AddEditSchemeScreen({super.key, this.scheme});

  @override
  _AddEditSchemeScreenState createState() => _AddEditSchemeScreenState();
}

class _AddEditSchemeScreenState extends State<AddEditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _schemeNameController;
  late TextEditingController _monthlyInstallmentController;
  late TextEditingController _propertyValueController;
  late TextEditingController _downPaymentController;
  late TextEditingController _loanAmountController;
  late TextEditingController _interestRateController;
  late String _loanType;
  late bool _employmentStatus;
  bool _isSubmitting = false;

  static const Color primaryGreen = Color(0xFF108224);

  final List<String> _loanTypes = [
    'Home Loan',
    'Personal Loan',
    'Business Loan',
    'Education Loan',
    'Car Loan'
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _schemeNameController = TextEditingController(text: widget.scheme?.schemeName ?? '');
    _monthlyInstallmentController = TextEditingController(
        text: widget.scheme?.monthlyInstallment != null
            ? widget.scheme!.monthlyInstallment!.toStringAsFixed(0)
            : '');
    _propertyValueController = TextEditingController(
        text: widget.scheme?.propertyValue != null
            ? widget.scheme!.propertyValue!.toStringAsFixed(0)
            : '');
    _downPaymentController = TextEditingController(
        text: widget.scheme?.downPayment != null
            ? widget.scheme!.downPayment!.toStringAsFixed(0)
            : '');
    _loanAmountController = TextEditingController(
        text: widget.scheme?.loanAmount != null
            ? widget.scheme!.loanAmount!.toStringAsFixed(0)
            : '');
    _interestRateController = TextEditingController(
        text: widget.scheme?.interestRate != null
            ? widget.scheme!.interestRate!.toString()
            : '');
    _loanType = widget.scheme?.loanType ?? _loanTypes.first;
    _employmentStatus = widget.scheme?.employmentStatus ?? true;

    // Listeners for dynamic calculations & preview updates
    _propertyValueController.addListener(_recalcLoanAmount);
    _downPaymentController.addListener(_recalcLoanAmount);
    _monthlyInstallmentController.addListener(() => setState(() {}));
    _interestRateController.addListener(() => setState(() {}));
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add or edit financing schemes')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  void _recalcLoanAmount() {
    final prop = double.tryParse(_propertyValueController.text.trim()) ?? 0;
    final down = double.tryParse(_downPaymentController.text.trim()) ?? 0;
    if (prop > 0 && down >= 0 && down <= prop) {
      final calculated = prop - down;
      // If loan amount is empty or was previously matched, update it
      if (_loanAmountController.text.isEmpty ||
          double.tryParse(_loanAmountController.text) == null ||
          double.tryParse(_loanAmountController.text) == 0) {
        _loanAmountController.text = calculated.toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _schemeNameController.dispose();
    _monthlyInstallmentController.dispose();
    _propertyValueController.dispose();
    _downPaymentController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  String _formatPKR(num? amount) {
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ??
              (isRequired
                  ? (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required field';
                      }
                      return null;
                    }
                  : null),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: primaryGreen, size: 20),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            suffixText: suffixText,
            suffixStyle: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveMonthly = double.tryParse(_monthlyInstallmentController.text.trim()) ?? 0;
    final liveProp = double.tryParse(_propertyValueController.text.trim()) ?? 0;
    final liveDown = double.tryParse(_downPaymentController.text.trim()) ?? 0;
    final liveLoan = double.tryParse(_loanAmountController.text.trim()) ?? 0;
    final liveRate = double.tryParse(_interestRateController.text.trim()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: Text(
          widget.scheme == null ? 'Create Loan Scheme' : 'Edit Scheme',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LIVE SCHEME PREVIEW',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _loanType,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _schemeNameController.text.isNotEmpty
                                ? _schemeNameController.text
                                : 'Scheme Title Here',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Installment',
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                                  ),
                                  Text(
                                    _formatPKR(liveMonthly),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Interest Rate',
                                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                                  ),
                                  Text(
                                    '$liveRate% p.a.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (liveProp > 0) ...[
                            const SizedBox(height: 10),
                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prop: ${_formatPKR(liveProp)}',
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.5),
                                ),
                                Text(
                                  'Down: ${_formatPKR(liveDown)}',
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10.5),
                                ),
                                Text(
                                  'Loan: ${_formatPKR(liveLoan)}',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Section 1: Basic Information
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline,
                      children: [
                        _buildTextInputField(
                          controller: _schemeNameController,
                          label: 'Scheme Name *',
                          hint: 'e.g. Dhartti Easy Home Financing',
                          icon: Icons.account_balance,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter scheme name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan Type *',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _loanType,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: primaryGreen),
                                  items: _loanTypes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Icon(
                                            value.contains('Home')
                                                ? Icons.home
                                                : value.contains('Car')
                                                    ? Icons.directions_car
                                                    : Icons.account_balance_wallet,
                                            size: 18,
                                            color: primaryGreen,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            value,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _loanType = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Section 2: Financial Details
                    _buildSectionCard(
                      title: 'Financial Figures',
                      icon: Icons.monetization_on_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextInputField(
                                controller: _propertyValueController,
                                label: 'Property Value *',
                                hint: 'e.g. 10000000',
                                icon: Icons.home_work_outlined,
                                keyboardType: TextInputType.number,
                                prefixText: 'PKR ',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter value';
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) return 'Invalid amount';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextInputField(
                                controller: _downPaymentController,
                                label: 'Down Payment *',
                                hint: 'e.g. 2000000',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                prefixText: 'PKR ',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter down payment';
                                  final down = double.tryParse(val.trim());
                                  final prop = double.tryParse(_propertyValueController.text.trim()) ?? 0;
                                  if (down == null || down < 0) return 'Invalid amount';
                                  if (prop > 0 && down > prop) return 'Cannot exceed property value';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextInputField(
                                controller: _loanAmountController,
                                label: 'Loan Amount *',
                                hint: 'e.g. 8000000',
                                icon: Icons.account_balance_wallet_outlined,
                                keyboardType: TextInputType.number,
                                prefixText: 'PKR ',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter loan amount';
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) return 'Invalid amount';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextInputField(
                                controller: _monthlyInstallmentController,
                                label: 'Monthly Installment *',
                                hint: 'e.g. 55000',
                                icon: Icons.calendar_month_outlined,
                                keyboardType: TextInputType.number,
                                prefixText: 'PKR ',
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter installment';
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) return 'Invalid amount';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextInputField(
                          controller: _interestRateController,
                          label: 'Annual Interest Rate (%) *',
                          hint: 'e.g. 7.5',
                          icon: Icons.percent,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '% p.a.',
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter interest rate';
                            final num = double.tryParse(val.trim());
                            if (num == null || num < 0 || num > 100) return 'Invalid rate (0-100)';
                            return null;
                          },
                        ),
                      ],
                    ),

                    // Section 3: Eligibility & Requirements
                    _buildSectionCard(
                      title: 'Eligibility Requirements',
                      icon: Icons.verified_user_outlined,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Employment Status Required',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            subtitle: Text(
                              _employmentStatus
                                  ? 'Applicant must be employed with regular income'
                                  : 'Open for self-employed or flexible applicants',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            value: _employmentStatus,
                            activeColor: primaryGreen,
                            onChanged: (value) {
                              setState(() {
                                _employmentStatus = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 2,
                          shadowColor: primaryGreen.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.scheme == null ? Icons.add_circle_outline : Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.scheme == null ? 'Publish Scheme' : 'Update Scheme',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final scheme = Scheme(
          id: widget.scheme?.id ?? 0,
          userId: widget.scheme?.userId ?? 0,
          schemeName: _schemeNameController.text.trim(),
          monthlyInstallment: double.parse(_monthlyInstallmentController.text.trim()),
          propertyValue: double.parse(_propertyValueController.text.trim()),
          downPayment: double.parse(_downPaymentController.text.trim()),
          loanAmount: double.parse(_loanAmountController.text.trim()),
          interestRate: double.parse(_interestRateController.text.trim()),
          loanType: _loanType,
          employmentStatus: _employmentStatus,
        );

        if (widget.scheme == null) {
          await SchemeService.createScheme(scheme);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Scheme created successfully!',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } else {
          await SchemeService.updateScheme(scheme);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Scheme updated successfully!',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}
