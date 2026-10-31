import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/Model/joinVenture.dart';
import 'package:dhartti/service/join_venture_service.dart';

class AddJoinVentureScreen extends StatefulWidget {
  final JoinVenture? venture;

  const AddJoinVentureScreen({super.key, this.venture});

  @override
  State<AddJoinVentureScreen> createState() => _AddJoinVentureScreenState();
}

class _AddJoinVentureScreenState extends State<AddJoinVentureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedIndustry = 'Real Estate';
  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF108224);

  final List<String> _industries = [
    'Real Estate',
    'Construction',
    'Commercial Development',
    'Architecture & Design',
    'Town Planning',
    'Infrastructure',
    'Other',
  ];

  final List<String> _commonCities = [
    'Islamabad',
    'Rawalpindi',
    'Lahore',
    'Karachi',
    'Peshawar',
    'Multan',
    'Faisalabad',
    'Gwadar',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.venture != null) {
      _titleController.text = widget.venture!.title;
      _descriptionController.text = widget.venture!.description;
      _locationController.text = widget.venture!.location ?? '';
      if (_industries.contains(widget.venture!.industry)) {
        _selectedIndustry = widget.venture!.industry;
      } else if (widget.venture!.industry.isNotEmpty) {
        _selectedIndustry = widget.venture!.industry;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ventureData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'industry': _selectedIndustry,
        'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      };

      if (widget.venture != null) {
        await JoinVentureService().updateJoinVenture(widget.venture!.id, ventureData);
      } else {
        await JoinVentureService().createJoinVenture(ventureData);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  widget.venture == null
                      ? 'Joint Venture posted successfully!'
                      : 'Joint Venture updated successfully!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.venture != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Joint Venture' : 'Create Joint Venture',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  SizedBox(height: 16),
                  Text('Publishing Venture Opportunity...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Guidance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.handshake_rounded, color: primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Partner & Grow Together',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Invite certified contractors and real estate investors to collaborate on your venture proposal.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
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

                    // Section 1: Title
                    _buildFieldLabel('Venture Title *', Icons.title_rounded),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'e.g., Commercial Plaza Joint Venture Phase 8',
                        prefixIcon: Icons.business_center_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a clear descriptive title';
                        }
                        if (value.trim().length < 6) {
                          return 'Title should be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Industry Sector Selector
                    _buildFieldLabel('Industry Sector *', Icons.category_rounded),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _industries.contains(_selectedIndustry) ? _selectedIndustry : _industries.first,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen),
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                          items: _industries.map((ind) {
                            return DropdownMenuItem<String>(
                              value: ind,
                              child: Text(ind),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedIndustry = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Location / City
                    _buildFieldLabel('Project Location / City *', Icons.location_on_rounded),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration(
                        hint: 'e.g., DHA Phase 6, Lahore',
                        prefixIcon: Icons.map_outlined,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter project location' : null,
                    ),
                    const SizedBox(height: 10),

                    // Quick City Suggestion Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _commonCities.map((city) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _locationController.text = city;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '+ $city',
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF475569)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Detailed Proposal & Description
                    _buildFieldLabel('Proposal & Scope of Partnership *', Icons.description_rounded),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      style: GoogleFonts.poppins(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Describe project details, investment requirements, profit sharing ratio, required contractor expertise, timeline, etc.',
                        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a detailed description of your venture';
                        }
                        if (value.trim().length < 20) {
                          return 'Description should be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'UPDATE VENTURE' : 'PUBLISH JOINT VENTURE',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryGreen),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade400),
      prefixIcon: Icon(prefixIcon, color: primaryGreen, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}
