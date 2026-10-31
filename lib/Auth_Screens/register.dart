import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Common credentials controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Role-specific controllers
  final TextEditingController agencyNameController = TextEditingController();
  final TextEditingController firmNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();

  int _selectedRoleId = 1; // 1 = Buyer/User, 2 = Seller, 3 = Contractor
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Contractor dropdown options
  String _selectedSpecialization = "Civil Construction";
  final List<String> _specializations = [
    "Civil Construction",
    "Grey Structure",
    "Architecture & Design",
    "Renovation & Remodeling",
    "Interior Design",
    "Electric & Plumbing",
  ];

  String _selectedExperience = "3-5 Years";
  final List<String> _experienceLevels = [
    "1-2 Years",
    "3-5 Years",
    "5-10 Years",
    "10+ Years",
  ];

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color lightBg = Color(0xFFF8FAF8);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    agencyNameController.dispose();
    firmNameController.dispose();
    cityController.dispose();
    cnicController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await _authService.registerUserDetailed(
      nameController.text.trim(),
      emailController.text.trim(),
      contactController.text.trim(),
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
      roleId: _selectedRoleId,
      agencyName: _selectedRoleId == 2 ? agencyNameController.text.trim() : null,
      firmName: _selectedRoleId == 3 ? firmNameController.text.trim() : null,
      city: (_selectedRoleId == 2 || _selectedRoleId == 3) ? cityController.text.trim() : null,
      cnic: _selectedRoleId == 2 ? cnicController.text.trim() : null,
      specialization: _selectedRoleId == 3 ? _selectedSpecialization : null,
      experienceYears: _selectedRoleId == 3 ? _selectedExperience : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final isPending = res['pending_approval'] == true || _selectedRoleId > 1;

      if (isPending) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text("Approval Pending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              _selectedRoleId == 2
                  ? "Your account has been created! Your Seller application has been submitted to the Dhartti Super Admin for verification. Once approved, your Seller dashboard will be unlocked. You can explore the platform as a buyer meanwhile."
                  : "Your account has been created! Your Contractor application has been submitted to the Dhartti Super Admin for verification. Once approved, your Contractor dashboard will be unlocked. You can explore the platform as a buyer meanwhile.",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
                  );
                },
                child: const Text("Continue to App", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully! Welcome to Dhartti."),
            backgroundColor: dharttiGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Registration Failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dharttiGreen.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/nlogo.png',
                          height: 60,
                          width: 60,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.home_work_rounded,
                            color: dharttiGreen,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title & Subtitle
                    const Text(
                      "Create Your Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Georgia',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose your role to get a tailored registration form",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Role Selector Cards
                    _buildLabel("Select Account Role"),
                    const SizedBox(height: 8),
                    _buildRoleSelector(),

                    const SizedBox(height: 16),

                    // Role Informational Banner
                    _buildRoleBanner(),

                    const SizedBox(height: 20),

                    // DYNAMIC ROLE-SPECIFIC FIELDS
                    if (_selectedRoleId == 2) ...[
                      _buildSectionHeader(
                        icon: Icons.business_center_rounded,
                        title: "Agency & Business Details",
                      ),
                      const SizedBox(height: 12),

                      // Agency / Business Name
                      _buildLabel("Agency / Business Name *"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: agencyNameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "e.g. Al-Madina Real Estate / Individual",
                          prefixIcon: Icons.storefront_outlined,
                        ),
                        validator: (value) {
                          if (_selectedRoleId == 2 && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your agency or business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Operating City
                      _buildLabel("Operating City / Area *"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: cityController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "e.g. Islamabad, Lahore, Karachi, Abbottabad",
                          prefixIcon: Icons.location_city_outlined,
                        ),
                        validator: (value) {
                          if (_selectedRoleId == 2 && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your operating city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // CNIC (Optional)
                      _buildLabel("CNIC / NTN (Optional for Verified Badge)"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: cnicController,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "e.g. 37405-XXXXXXX-X",
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedRoleId == 3) ...[
                      _buildSectionHeader(
                        icon: Icons.construction_rounded,
                        title: "Construction Firm & Trade Details",
                      ),
                      const SizedBox(height: 12),

                      // Firm / Company Name
                      _buildLabel("Construction Firm / Contractor Name *"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: firmNameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "e.g. Apex Builders & Constructors",
                          prefixIcon: Icons.apartment_rounded,
                        ),
                        validator: (value) {
                          if (_selectedRoleId == 3 && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your firm or business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Primary Specialization Dropdown
                      _buildLabel("Primary Specialization *"),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSpecialization,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "Select Specialization",
                          prefixIcon: Icons.handyman_outlined,
                        ),
                        dropdownColor: Colors.white,
                        items: _specializations.map((spec) {
                          return DropdownMenuItem(
                            value: spec,
                            child: Text(spec),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSpecialization = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Operating City
                      _buildLabel("Operating City *"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: cityController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "e.g. Rawalpindi, Islamabad, Peshawar",
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (_selectedRoleId == 3 && (value == null || value.trim().isEmpty)) {
                            return 'Please enter your primary operating city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Experience Level Dropdown
                      _buildLabel("Years of Experience *"),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExperience,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        decoration: _inputDecoration(
                          hint: "Select Experience",
                          prefixIcon: Icons.history_edu_outlined,
                        ),
                        dropdownColor: Colors.white,
                        items: _experienceLevels.map((exp) {
                          return DropdownMenuItem(
                            value: exp,
                            child: Text(exp),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedExperience = val);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // COMMON / REPRESENTATIVE CONTACT DETAILS
                    _buildSectionHeader(
                      icon: Icons.person_pin_circle_outlined,
                      title: _selectedRoleId == 1
                          ? "Personal Information"
                          : (_selectedRoleId == 2 ? "Owner / Representative Details" : "Lead Contractor / Engineer Details"),
                    ),
                    const SizedBox(height: 12),

                    // Full Name Field
                    _buildLabel(_selectedRoleId == 1
                        ? "Full Name *"
                        : (_selectedRoleId == 2 ? "Owner / Authorized Contact Name *" : "Lead Engineer / Contractor Name *")),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(
                        hint: _selectedRoleId == 1 ? "Enter your full name" : "e.g. Engr. Hamza Khan",
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email Field
                    _buildLabel(_selectedRoleId == 1 ? "Email Address *" : "Official Email Address *"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(
                        hint: "name@example.com",
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Contact Number Field
                    _buildLabel(_selectedRoleId == 1 ? "Mobile Number *" : "WhatsApp / Mobile Number *"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(
                        hint: "e.g. 03001234567",
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your contact number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number (10-11 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    _buildLabel("Account Password *"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(
                        hint: "At least 8 characters",
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password Field
                    _buildLabel("Confirm Password *"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration(
                        hint: "Re-enter your password",
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Terms Notice
                    Text(
                      "By signing up, you agree to Dhartti's Terms of Service and Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Register Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dharttiGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                _selectedRoleId == 2
                                    ? "Register As Property Seller"
                                    : (_selectedRoleId == 3 ? "Register As Contractor" : "Create Buyer Account"),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Footer Link to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: dharttiGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBanner() {
    String message;
    IconData icon;

    switch (_selectedRoleId) {
      case 2:
        message = "Post & manage your property listings, projects, and store items with dedicated seller tools.";
        icon = Icons.apartment_rounded;
        break;
      case 3:
        message = "Bid on construction ventures, offer specialized contracting services, and win project contracts.";
        icon = Icons.construction_rounded;
        break;
      default:
        message = "Explore verified real estate, contact sellers directly, save properties, and order store products.";
        icon = Icons.shopping_bag_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dharttiGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dharttiGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dharttiGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.green.shade900, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: dharttiGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: Colors.grey.shade200, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            roleId: 1,
            title: "Buyer / User",
            subtitle: "Browse & Buy",
            icon: Icons.person_pin_circle_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleCard(
            roleId: 2,
            title: "Seller",
            subtitle: "Post & Sell",
            icon: Icons.apartment_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleCard(
            roleId: 3,
            title: "Contractor",
            subtitle: "Bids & Builds",
            icon: Icons.construction_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required int roleId,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRoleId == roleId;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRoleId = roleId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F7EC) : lightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? dharttiGreen : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: dharttiGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? dharttiGreen : Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? dharttiGreen : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? dharttiGreen.withValues(alpha: 0.8) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(prefixIcon, color: dharttiGreen, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dharttiGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
