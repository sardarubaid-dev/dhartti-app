import 'package:flutter/material.dart';
import 'package:dhartti/service/project_service.dart';

class EditProjectScreen extends StatefulWidget {
  final int projectId;

  const EditProjectScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _EditProjectScreenState createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = ProjectService();
  final _scrollController = ScrollController();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailController = TextEditingController();
  final _cityController = TextEditingController();
  final _offeringController = TextEditingController();
  final _propertyTypeController = TextEditingController();
  final _currencyController = TextEditingController();
  final _areaUnitController = TextEditingController();
  final _developerTitleController = TextEditingController();
  final _budgetRangeMinController = TextEditingController();
  final _budgetRangeMaxController = TextEditingController();
  final _floorAreaUnitController = TextEditingController();
  final _floorCurrencyController = TextEditingController();
  final _imageController = TextEditingController();
  final _videoController = TextEditingController();
  final _image2Controller = TextEditingController();
  final _image3Controller = TextEditingController();
  final _areaRangeController = TextEditingController();
  final _priceRangesController = TextEditingController();
  final _addressesController = TextEditingController();
  final _floorAreaRangeController = TextEditingController();
  final _floorPriceRangesController = TextEditingController();
  final _floorAddressesController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProject();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProject() async {
    setState(() => _isLoading = true);
    try {
      final project = await _projectService.fetchProjectss(widget.projectId);

      setState(() {
        _titleController.text = project['title'] ?? '';
        _descriptionController.text = project['description'] ?? '';
        _detailController.text = project['detail'] ?? '';
        _cityController.text = project['city'] ?? '';
        _offeringController.text = project['offering'] ?? '';
        _propertyTypeController.text = project['property_type'] ?? '';
        _currencyController.text = project['currency'] ?? '';
        _areaUnitController.text = project['area_unit'] ?? '';
        _developerTitleController.text = project['developer_title'] ?? '';
        _budgetRangeMinController.text = project['budget_range_min']?.toString() ?? '';
        _budgetRangeMaxController.text = project['budget_range_max']?.toString() ?? '';
        _areaRangeController.text = project['area_range'] ?? '';
        _priceRangesController.text = project['price_ranges'] ?? '';
        _addressesController.text = project['addresses'] ?? '';
        _floorAreaRangeController.text = project['floor_area_range'] ?? '';
        _floorPriceRangesController.text = project['floor_price_ranges'] ?? '';
        _floorAddressesController.text = project['floor_addresses'] ?? '';
        _floorAreaUnitController.text = project['floor_area_unit'] ?? '';
        _floorCurrencyController.text = project['floor_currency'] ?? '';
        _imageController.text = project['image'] ?? '';
        _videoController.text = project['video'] ?? '';
        _image2Controller.text = project['image_2'] ?? '';
        _image3Controller.text = project['image_3'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch project details'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedProject = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'detail': _detailController.text,
        'city': _cityController.text,
        'offering': _offeringController.text,
        'property_type': _propertyTypeController.text,
        'currency': _currencyController.text,
        'area_unit': _areaUnitController.text,
        'developer_title': _developerTitleController.text,
        'budget_range_min': _budgetRangeMinController.text,
        'budget_range_max': _budgetRangeMaxController.text,
        'area_range': _areaRangeController.text,
        'price_ranges': _priceRangesController.text,
        'addresses': _addressesController.text,
        'floor_area_range': _floorAreaRangeController.text,
        'floor_price_ranges': _floorPriceRangesController.text,
        'floor_addresses': _floorAddressesController.text,
        'floor_area_unit': _floorAreaUnitController.text,
        'floor_currency': _floorCurrencyController.text,
        'image': _imageController.text,
        'video': _videoController.text,
        'image_2': _image2Controller.text,
        'image_3': _image3Controller.text,
      };

      final success = await _projectService.updateProject(widget.projectId, updatedProject);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update project: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.teal[800],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: isRequired
            ? (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Project', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _updateProject,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Basic Information Section
                _buildSectionHeader('Basic Information'),
                _buildFormField(
                  controller: _titleController,
                  label: 'Project Title',
                  isRequired: true,
                ),
                _buildFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  isRequired: true,
                  maxLines: 3,
                ),
                _buildFormField(
                  controller: _detailController,
                  label: 'Details',
                  maxLines: 4,
                ),

                // Location Information
                _buildSectionHeader('Location Information'),
                _buildFormField(
                  controller: _cityController,
                  label: 'City',
                ),
                _buildFormField(
                  controller: _addressesController,
                  label: 'Addresses (JSON)',
                  maxLines: 3,
                ),

                // Property Details
                _buildSectionHeader('Property Details'),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _propertyTypeController,
                        label: 'Property Type',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: _offeringController,
                        label: 'Offering',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _currencyController,
                        label: 'Currency',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: _areaUnitController,
                        label: 'Area Unit',
                      ),
                    ),
                  ],
                ),

                // Budget Information
                _buildSectionHeader('Budget Information'),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _budgetRangeMinController,
                        label: 'Min Budget',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: _budgetRangeMaxController,
                        label: 'Max Budget',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _buildFormField(
                  controller: _priceRangesController,
                  label: 'Price Ranges (JSON)',
                  maxLines: 3,
                ),

                // Area Information
                _buildSectionHeader('Area Information'),
                _buildFormField(
                  controller: _areaRangeController,
                  label: 'Area Range (JSON)',
                  maxLines: 3,
                ),
                _buildFormField(
                  controller: _floorAreaRangeController,
                  label: 'Floor Area Range (JSON)',
                  maxLines: 3,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _floorAreaUnitController,
                        label: 'Floor Area Unit',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: _floorCurrencyController,
                        label: 'Floor Currency',
                      ),
                    ),
                  ],
                ),

                // Media Section
                _buildSectionHeader('Media'),
                _buildFormField(
                  controller: _imageController,
                  label: 'Main Image URL',
                ),
                _buildFormField(
                  controller: _image2Controller,
                  label: 'Secondary Image URL',
                ),
                _buildFormField(
                  controller: _image3Controller,
                  label: 'Additional Image URL',
                ),
                _buildFormField(
                  controller: _videoController,
                  label: 'Video URL',
                ),

                // Developer Information
                _buildSectionHeader('Developer Information'),
                _buildFormField(
                  controller: _developerTitleController,
                  label: 'Developer Title',
                ),

                // Additional Information
                _buildSectionHeader('Additional Information'),
                _buildFormField(
                  controller: _floorPriceRangesController,
                  label: 'Floor Price Ranges (JSON)',
                  maxLines: 3,
                ),
                _buildFormField(
                  controller: _floorAddressesController,
                  label: 'Floor Addresses (JSON)',
                  maxLines: 3,
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 40),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Text(
                      'UPDATE PROJECT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
