import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/service/auth_service.dart';

class RoleUpgradeFormScreen extends StatefulWidget {
  final int targetRole; // 2 = Seller, 3 = Contractor

  const RoleUpgradeFormScreen({super.key, required this.targetRole});

  @override
  State<RoleUpgradeFormScreen> createState() => _RoleUpgradeFormScreenState();
}

class _RoleUpgradeFormScreenState extends State<RoleUpgradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController(); // Seller
  final TextEditingController _specializationController = TextEditingController(); // Contractor
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController(); // Seller
  final TextEditingController _portfolioController = TextEditingController(); // Contractor

  bool _isLoadingStatus = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingPendingRequest;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color darkSlate = Color(0xFF161E2D);
  static const Color accentAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoadingStatus = true);
    await _prefillUserData();
    await _checkExistingRequest();
    if (mounted) {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _prefillUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? prefs.getString('userName');
    final contact = prefs.getString('contact_number') ?? prefs.getString('userPhone');

    if (name != null && name.isNotEmpty && _fullNameController.text.isEmpty) {
      _fullNameController.text = name;
    }
    if (contact != null && contact.isNotEmpty && _contactNumberController.text.isEmpty) {
      _contactNumberController.text = contact;
    }
  }

  Future<void> _checkExistingRequest() async {
    try {
      final res = await _authService.getUpgradeStatus();
      if (res['has_request'] == true && res['request'] != null) {
        final req = res['request'];
        if (req['status'] == 'pending') {
          _existingPendingRequest = req;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cnicController.dispose();
    _contactNumberController.dispose();
    _companyNameController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_existingPendingRequest != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an upgrade request under review by Super Admin.'),
          backgroundColor: accentAmber,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final bool isSeller = widget.targetRole == 2;
    final Map<String, dynamic> details = {
      'role': isSeller ? 'seller' : 'contractor',
      'full_name': _fullNameController.text.trim(),
      'cnic': _cnicController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'company_name': _companyNameController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (isSeller) {
      details['agency_name'] = _companyNameController.text.trim();
      details['experience'] = _experienceController.text.trim();
      details['reason'] = _reasonController.text.trim();
    } else {
      details['firm_name'] = _companyNameController.text.trim();
      details['specialization'] = _specializationController.text.trim();
      details['portfolio'] = _portfolioController.text.trim();
    }

    final res = await _authService.upgradeRole(
      widget.targetRole,
      details: details,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to submit verification request'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final isSeller = widget.targetRole == 2;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: dharttiGreen, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'Application Submitted!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your request to become a ${isSeller ? "Seller" : "Contractor"} has been submitted and is currently pending Super Admin approval.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeller = widget.targetRole == 2;
    final String roleTitle = isSeller ? 'Become a Seller' : 'Become a Contractor';
    final String formTitle = isSeller ? 'Seller Verification Form' : 'Contractor Verification Form';
    final Color roleColor = isSeller ? const Color(0xFFEA580C) : const Color(0xFF0D9488);

    if (_isLoadingStatus) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(roleTitle, style: GoogleFonts.poppins(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 17)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(color: dharttiGreen)),
      );
    }

    // IF ALREADY PENDING: STRICTLY BLOCK FORM DISPLAY
    if (_existingPendingRequest != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Verification Status', style: GoogleFonts.poppins(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 17)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: accentAmber, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Application Already Under Review',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: darkSlate),
              ),
              const SizedBox(height: 10),
              Text(
                'You already have a pending upgrade application under review by the Super Admin. You cannot submit multiple requests.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkSlate,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          roleTitle,
          style: GoogleFonts.poppins(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isSeller ? Icons.storefront_rounded : Icons.construction_rounded,
                        color: roleColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formTitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please provide accurate details for swift Super Admin verification.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Full Name
                    _buildLabel('Full Name (as per CNIC) *'),
                    _buildTextField(
                      controller: _fullNameController,
                      hintText: 'e.g. Muhammad Ali',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name as per CNIC' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: CNIC Number
                    _buildLabel('CNIC Number *'),
                    _buildTextField(
                      controller: _cnicController,
                      hintText: 'XXXXX-XXXXXXX-X',
                      keyboardType: TextInputType.number,
                      icon: Icons.credit_card_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter CNIC number';
                        if (v.trim().replaceAll('-', '').length < 13) return 'CNIC must have 13 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Contact Number
                    _buildLabel('Contact Number *'),
                    _buildTextField(
                      controller: _contactNumberController,
                      hintText: '03XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter contact number' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 4: Company / Business Name
                    _buildLabel(isSeller ? 'Agency / Company Name *' : 'Construction / Builder Name *'),
                    _buildTextField(
                      controller: _companyNameController,
                      hintText: isSeller ? 'Your real estate agency' : 'Your business/firm name',
                      icon: Icons.business_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter business name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 5: Experience (Seller) OR Specialization (Contractor)
                    if (isSeller) ...[
                      _buildLabel('Years of Experience *'),
                      _buildTextField(
                        controller: _experienceController,
                        hintText: 'e.g. 5',
                        keyboardType: TextInputType.number,
                        icon: Icons.history_edu_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify years of experience' : null,
                      ),
                    ] else ...[
                      _buildLabel('Specialization (e.g. Civil, Interior, Grey Structure) *'),
                      _buildTextField(
                        controller: _specializationController,
                        hintText: 'Your core expertise',
                        icon: Icons.handyman_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify your specialization' : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Field 6: Full Address
                    _buildLabel('Full Address (City / Office) *'),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Complete address for verification',
                      maxLines: 2,
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter complete address' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 7: Reason (Seller) OR Portfolio (Contractor)
                    if (isSeller) ...[
                      _buildLabel('Why do you want to join as a Seller? *'),
                      _buildTextField(
                        controller: _reasonController,
                        hintText: 'Describe your real estate background or inventory size...',
                        maxLines: 3,
                        icon: Icons.chat_bubble_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a reason' : null,
                      ),
                    ] else ...[
                      _buildLabel('Portfolio / Previous Work Links *'),
                      _buildTextField(
                        controller: _portfolioController,
                        hintText: 'Describe past construction projects or paste portfolio links...',
                        maxLines: 3,
                        icon: Icons.link_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe past projects or paste links' : null,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkSlate,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Submit Verification Request',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.8,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13.5, color: darkSlate),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          borderSide: const BorderSide(color: dharttiGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
    );
  }
}
