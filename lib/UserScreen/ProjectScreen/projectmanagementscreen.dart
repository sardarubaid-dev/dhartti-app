import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RangePair {
  final TextEditingController minController;
  final TextEditingController maxController;

  RangePair({String min = '', String max = ''})
      : minController = TextEditingController(text: min),
        maxController = TextEditingController(text: max);

  void dispose() {
    minController.dispose();
    maxController.dispose();
  }

  Map<String, String> toJson() => {
    'min': minController.text.trim(),
    'max': maxController.text.trim(),
  };
}

class AddressEntry {
  final TextEditingController lineController;

  AddressEntry({String line = ''})
      : lineController = TextEditingController(text: line);

  void dispose() {
    lineController.dispose();
  }

  Map<String, String> toJson() => {
    'line': lineController.text.trim(),
  };
}

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailController = TextEditingController();
  final _cityController = TextEditingController();
  String _propertyType = 'Apartment';
  String _offering = 'Sale';

  // Pricing & Area Units
  String _currency = 'PKR';
  final _budgetRangeMinController = TextEditingController();
  final _budgetRangeMaxController = TextEditingController();
  String _areaUnit = 'marla';

  // Floor Information
  String _floorCurrency = 'PKR';
  String _floorAreaUnit = 'sqft';

  // Developer & Media
  final _developerTitleController = TextEditingController();
  final _videoController = TextEditingController();

  // Images
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  File? _imageFile2;
  File? _imageFile3;

  // Dynamic Range & Address Pairs (Matching Web Parity)
  final List<RangePair> _priceRanges = [RangePair()];
  final List<RangePair> _areaRanges = [RangePair()];
  final List<AddressEntry> _addresses = [AddressEntry()];
  final List<RangePair> _floorAreaRanges = [RangePair()];
  final List<RangePair> _floorPriceRanges = [RangePair()];
  final List<AddressEntry> _floorAddresses = [AddressEntry()];

  // Loading state
  bool _isLoading = false;

  static const Color dharttiGreen = Color(0xFF108224);

  final List<String> _propertyTypes = [
    'Apartment',
    'Villa',
    'Plot',
    'House',
    'Commercial',
    'Penthouse',
    'Duplex',
  ];

  final List<String> _offeringTypes = [
    'Sale',
    'Rent',
    'Lease',
  ];

  final List<String> _currencies = [
    'PKR',
    'USD',
    'EUR',
    'AED',
    'GBP',
  ];

  final List<Map<String, String>> _areaUnits = [
    {'value': 'marla', 'label': 'Marla'},
    {'value': 'sqft', 'label': 'Sq. Feet (sqft)'},
    {'value': 'sqm', 'label': 'Sq. Meter (sqm)'},
    {'value': 'sqyd', 'label': 'Sq. Yards (sqyd)'},
    {'value': 'kanal', 'label': 'Kanal'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailController.dispose();
    _cityController.dispose();
    _budgetRangeMinController.dispose();
    _budgetRangeMaxController.dispose();
    _developerTitleController.dispose();
    _videoController.dispose();

    for (var r in _priceRanges) { r.dispose(); }
    for (var r in _areaRanges) { r.dispose(); }
    for (var a in _addresses) { a.dispose(); }
    for (var r in _floorAreaRanges) { r.dispose(); }
    for (var r in _floorPriceRanges) { r.dispose(); }
    for (var a in _floorAddresses) { a.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Add New Project',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: dharttiGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Basic Information
                    _buildSectionCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Basic Information',
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'Project Title *',
                          hint: 'e.g. Luxury Hills Apartments',
                          icon: Icons.apartment_rounded,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'Project Title is required' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _cityController,
                          label: 'City *',
                          hint: 'e.g. Karachi, Lahore, Islamabad',
                          icon: Icons.location_city_rounded,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'City is required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Property Type *',
                                value: _propertyType,
                                items: _propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _propertyType = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Offering Type *',
                                value: _offering,
                                items: _offeringTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _offering = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Brief Description * (Max 150 chars)',
                          hint: 'Short description that appears in listings',
                          icon: Icons.short_text_rounded,
                          maxLines: 2,
                          maxLength: 150,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'Brief description is required' : null,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _detailController,
                          label: 'Detailed Information *',
                          hint: 'Full details and features about the project',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                          validator: (v) => v?.trim().isEmpty ?? true ? 'Detailed information is required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Media Section
                    _buildSectionCard(
                      icon: Icons.photo_library_outlined,
                      title: 'Media & Visuals',
                      children: [
                        _buildImagePickerRow(
                          label: 'Main Image * (Cover)',
                          file: _imageFile,
                          onPick: () => _pickImage(1),
                          onRemove: () => setState(() => _imageFile = null),
                        ),
                        const SizedBox(height: 14),
                        _buildImagePickerRow(
                          label: 'Secondary Image (Gallery)',
                          file: _imageFile2,
                          onPick: () => _pickImage(2),
                          onRemove: () => setState(() => _imageFile2 = null),
                        ),
                        const SizedBox(height: 14),
                        _buildImagePickerRow(
                          label: 'Additional Image (Gallery)',
                          file: _imageFile3,
                          onPick: () => _pickImage(3),
                          onRemove: () => setState(() => _imageFile3 = null),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _videoController,
                          label: 'Video URL or Embed Link',
                          hint: 'e.g. YouTube or Vimeo link',
                          icon: Icons.video_collection_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Pricing Information
                    _buildSectionCard(
                      icon: Icons.monetization_on_outlined,
                      title: 'Pricing & Budget Information',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Currency',
                                value: _currency,
                                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _currency = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Area Unit *',
                                value: _areaUnit,
                                items: _areaUnits.map((u) => DropdownMenuItem(value: u['value'], child: Text(u['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _areaUnit = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _budgetRangeMinController,
                                label: 'Min Budget *',
                                hint: 'e.g. 5000000',
                                icon: Icons.arrow_downward_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _budgetRangeMaxController,
                                label: 'Max Budget *',
                                hint: 'e.g. 10000000',
                                icon: Icons.arrow_upward_rounded,
                                keyboardType: TextInputType.number,
                                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Price Ranges (Pairs)
                        _buildRangeSectionHeader(
                          title: 'Price Ranges (Min - Max)',
                          onAdd: () {
                            setState(() {
                              _priceRanges.add(RangePair());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._priceRanges.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pair = entry.value;
                          return _buildRangePairRow(
                            pair: pair,
                            minLabel: 'Min Price',
                            maxLabel: 'Max Price',
                            canDelete: _priceRanges.length > 1,
                            onDelete: () => setState(() {
                              pair.dispose();
                              _priceRanges.removeAt(idx);
                            }),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Area Ranges Section
                    _buildSectionCard(
                      icon: Icons.straighten_rounded,
                      title: 'Area Ranges',
                      children: [
                        _buildRangeSectionHeader(
                          title: 'Area Ranges (Min - Max)',
                          onAdd: () {
                            setState(() {
                              _areaRanges.add(RangePair());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._areaRanges.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pair = entry.value;
                          return _buildRangePairRow(
                            pair: pair,
                            minLabel: 'Min Area',
                            maxLabel: 'Max Area',
                            canDelete: _areaRanges.length > 1,
                            onDelete: () => setState(() {
                              pair.dispose();
                              _areaRanges.removeAt(idx);
                            }),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Address Information
                    _buildSectionCard(
                      icon: Icons.location_on_outlined,
                      title: 'Project Addresses',
                      children: [
                        _buildRangeSectionHeader(
                          title: 'Address Lines',
                          onAdd: () {
                            setState(() {
                              _addresses.add(AddressEntry());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._addresses.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final addr = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: addr.lineController,
                                    label: 'Address ${idx + 1}',
                                    hint: 'e.g. Plot 23, Street 5, DHA Phase 6',
                                    icon: Icons.signpost_outlined,
                                  ),
                                ),
                                if (_addresses.length > 1) ...[
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        addr.dispose();
                                        _addresses.removeAt(idx);
                                      }),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 38,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 6. Floor Information
                    _buildSectionCard(
                      icon: Icons.layers_outlined,
                      title: 'Floor Information',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Floor Currency',
                                value: _floorCurrency,
                                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _floorCurrency = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Floor Area Unit',
                                value: _floorAreaUnit,
                                items: _areaUnits.map((u) => DropdownMenuItem(value: u['value'], child: Text(u['label']!, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _floorAreaUnit = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Floor Area Ranges
                        _buildRangeSectionHeader(
                          title: 'Floor Area Ranges (Min - Max)',
                          onAdd: () {
                            setState(() {
                              _floorAreaRanges.add(RangePair());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._floorAreaRanges.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pair = entry.value;
                          return _buildRangePairRow(
                            pair: pair,
                            minLabel: 'Min Area',
                            maxLabel: 'Max Area',
                            canDelete: _floorAreaRanges.length > 1,
                            onDelete: () => setState(() {
                              pair.dispose();
                              _floorAreaRanges.removeAt(idx);
                            }),
                          );
                        }),
                        const SizedBox(height: 20),

                        // Floor Price Ranges
                        _buildRangeSectionHeader(
                          title: 'Floor Price Ranges (Min - Max)',
                          onAdd: () {
                            setState(() {
                              _floorPriceRanges.add(RangePair());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._floorPriceRanges.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pair = entry.value;
                          return _buildRangePairRow(
                            pair: pair,
                            minLabel: 'Min Price',
                            maxLabel: 'Max Price',
                            canDelete: _floorPriceRanges.length > 1,
                            onDelete: () => setState(() {
                              pair.dispose();
                              _floorPriceRanges.removeAt(idx);
                            }),
                          );
                        }),
                        const SizedBox(height: 20),

                        // Floor Addresses
                        _buildRangeSectionHeader(
                          title: 'Floor Addresses',
                          onAdd: () {
                            setState(() {
                              _floorAddresses.add(AddressEntry());
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        ..._floorAddresses.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final addr = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: addr.lineController,
                                    label: 'Floor Address ${idx + 1}',
                                    hint: 'e.g. Floor 5, Unit 12',
                                    icon: Icons.tag_rounded,
                                  ),
                                ),
                                if (_floorAddresses.length > 1) ...[
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        addr.dispose();
                                        _floorAddresses.removeAt(idx);
                                      }),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 38,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 7. Developer Information
                    _buildSectionCard(
                      icon: Icons.engineering_outlined,
                      title: 'Developer Information',
                      children: [
                        _buildTextField(
                          controller: _developerTitleController,
                          label: 'Developer Name / Company',
                          hint: 'e.g. ABC Developers Ltd.',
                          icon: Icons.business_center_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dharttiGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                'Submit Project',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: dharttiGreen),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Icon(icon, color: dharttiGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600, size: 18) : null,
            prefixIconConstraints: icon != null ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSectionHeader({
    required String title,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, size: 15, color: dharttiGreen),
                const SizedBox(width: 4),
                Text(
                  'Add More',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: dharttiGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangePairRow({
    required RangePair pair,
    required String minLabel,
    required String maxLabel,
    required bool canDelete,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildTextField(
              controller: pair.minController,
              label: minLabel,
              hint: 'Min',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTextField(
              controller: pair.maxController,
              label: maxLabel,
              hint: 'Max',
              keyboardType: TextInputType.number,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600, size: 20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required File? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: file != null ? 140 : 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(file, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: dharttiGreen, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to choose image',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(int imageNumber) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          if (imageNumber == 1) _imageFile = File(picked.path);
          if (imageNumber == 2) _imageFile2 = File(picked.path);
          if (imageNumber == 3) _imageFile3 = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the Main Cover Image'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final rawUserId = prefs.get('userId');
      final userId = rawUserId != null ? rawUserId.toString() : '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ProjectService().baseUrl}/projects'),
      );

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      if (userId.isNotEmpty) {
        request.fields['userId'] = userId;
        request.fields['user_id'] = userId;
      }

      // Basic Information
      request.fields['title'] = _titleController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['property_type'] = _propertyType;
      request.fields['offering'] = _offering;
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['detail'] = _detailController.text.trim();

      // Pricing & Units
      request.fields['currency'] = _currency;
      request.fields['area_unit'] = _areaUnit;
      request.fields['budget_range_min'] = _budgetRangeMinController.text.trim();
      request.fields['budget_range_max'] = _budgetRangeMaxController.text.trim();

      // Dynamic Range Objects (Min / Max JSON pairs matching Web)
      request.fields['price_ranges'] = jsonEncode(
        _priceRanges
            .where((p) => p.minController.text.trim().isNotEmpty || p.maxController.text.trim().isNotEmpty)
            .map((p) => p.toJson())
            .toList(),
      );

      request.fields['area_range'] = jsonEncode(
        _areaRanges
            .where((a) => a.minController.text.trim().isNotEmpty || a.maxController.text.trim().isNotEmpty)
            .map((a) => a.toJson())
            .toList(),
      );

      request.fields['addresses'] = jsonEncode(
        _addresses
            .where((a) => a.lineController.text.trim().isNotEmpty)
            .map((a) => a.toJson())
            .toList(),
      );

      // Floor Information
      request.fields['floor_currency'] = _floorCurrency;
      request.fields['floor_area_unit'] = _floorAreaUnit;

      request.fields['floor_area_range'] = jsonEncode(
        _floorAreaRanges
            .where((p) => p.minController.text.trim().isNotEmpty || p.maxController.text.trim().isNotEmpty)
            .map((p) => p.toJson())
            .toList(),
      );

      request.fields['floor_price_ranges'] = jsonEncode(
        _floorPriceRanges
            .where((p) => p.minController.text.trim().isNotEmpty || p.maxController.text.trim().isNotEmpty)
            .map((p) => p.toJson())
            .toList(),
      );

      request.fields['floor_addresses'] = jsonEncode(
        _floorAddresses
            .where((a) => a.lineController.text.trim().isNotEmpty)
            .map((a) => a.toJson())
            .toList(),
      );

      // Developer Information
      request.fields['developer_title'] = _developerTitleController.text.trim();

      // Video URL
      if (_videoController.text.trim().isNotEmpty) {
        request.fields['video'] = _videoController.text.trim();
      }

      // Images
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      }
      if (_imageFile2 != null) {
        request.files.add(await http.MultipartFile.fromPath('image_2', _imageFile2!.path));
      }
      if (_imageFile3 != null) {
        request.files.add(await http.MultipartFile.fromPath('image_3', _imageFile3!.path));
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project created successfully!'),
              backgroundColor: dharttiGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create project: $responseBody'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
