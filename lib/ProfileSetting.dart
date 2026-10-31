import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: ProfileSettingsScreen(),
    theme: ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _obscurePassword = true;
  String? _selectedCurrency;
  String? _selectedAreaUnit;
  String? _selectedLanguage;

  // User data fields
  String? _name;
  String? _email;
  String? _phoneNumber;
  String? _password;

  // Dropdown options
  final List<String> _currencyOptions = ['USD', 'EUR', 'GBP', 'INR'];
  final List<String> _areaUnitOptions = ['Square Feet', 'Square Meters', 'Acres'];
  final List<String> _languageOptions = ['English', 'Spanish', 'French', 'German'];

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? '';
      _email = prefs.getString('email') ?? '';
      _phoneNumber = prefs.getString('contact_number') ?? '';
      _password = prefs.getString('password') ?? '';
      _selectedCurrency = prefs.getString('currency') ?? _currencyOptions.first;
      _selectedAreaUnit = prefs.getString('areaUnit') ?? _areaUnitOptions.first;
      _selectedLanguage = prefs.getString('language') ?? _languageOptions.first;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  void _showDropdownOptions(BuildContext context, List<String> options, String? selectedValue, Function(String?) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select an Option',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 16),
              ...options.map((option) {
                return ListTile(
                  title: Text(
                    option,
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Radio<String>(
                    value: option,
                    groupValue: selectedValue,
                    onChanged: onSelected,
                    activeColor: Colors.green,
                  ),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Information Section
            Text(
              'PROFILE INFORMATION',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Name',
              value: _name,
              icon: Icons.person_outline,
              onChanged: (value) => _name = value,
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Email',
              value: _email,
              icon: Icons.email_outlined,
              onChanged: (value) => _email = value,
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Password',
              value: _password,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              onChanged: (value) => _password = value,
            ),
            SizedBox(height: 16),
            _buildInputField(
              label: 'Phone Number',
              value: _phoneNumber,
              icon: Icons.phone_outlined,
              onChanged: (value) => _phoneNumber = value,
            ),
            SizedBox(height: 32),
            // General Settings Section
            Text(
              'GENERAL SETTINGS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16),
            _buildSettingOption(
              label: 'Currency',
              value: _selectedCurrency ?? 'Select Currency',
              icon: Icons.currency_exchange_outlined,
              onTap: () => _showDropdownOptions(
                context,
                _currencyOptions,
                _selectedCurrency,
                    (value) => setState(() => _selectedCurrency = value),
              ),
            ),
            SizedBox(height: 16),
            _buildSettingOption(
              label: 'Area Unit',
              value: _selectedAreaUnit ?? 'Select Area Unit',
              icon: Icons.straighten_outlined,
              onTap: () => _showDropdownOptions(
                context,
                _areaUnitOptions,
                _selectedAreaUnit,
                    (value) => setState(() => _selectedAreaUnit = value),
              ),
            ),
            SizedBox(height: 16),
            _buildSettingOption(
              label: 'Language',
              value: _selectedLanguage ?? 'Select Language',
              icon: Icons.language_outlined,
              onTap: () => _showDropdownOptions(
                context,
                _languageOptions,
                _selectedLanguage,
                    (value) => setState(() => _selectedLanguage = value),
              ),
            ),
            SizedBox(height: 32),
            // Account Actions Section
            Text(
              'ACCOUNT ACTIONS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16),
            _buildActionButton(
              icon: Icons.delete_outline,
              label: 'Delete Account',
              description: 'Permanently delete your account and all data',
              color: Colors.red,
              onPressed: () {
                // Handle delete account
              },
            ),
            SizedBox(height: 24),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('name', _name ?? '');
                  await prefs.setString('email', _email ?? '');
                  await prefs.setString('phoneNumber', _phoneNumber ?? '');
                  await prefs.setString('password', _password ?? '');
                  await prefs.setString('currency', _selectedCurrency ?? '');
                  await prefs.setString('areaUnit', _selectedAreaUnit ?? '');
                  await prefs.setString('language', _selectedLanguage ?? '');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settings saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String? value,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green, width: 1.5),
        ),
      ),
      style: GoogleFonts.poppins(),
      onChanged: onChanged,
    );
  }

  Widget _buildSettingOption({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
