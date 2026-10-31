import 'dart:io';
import 'package:dhartti/Model/store_model.dart';
import 'package:dhartti/service/seller_service.dart';
import 'package:dhartti/service/store_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddEditStoreProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;

  const AddEditStoreProductScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddEditStoreProductScreen> createState() => _AddEditStoreProductScreenState();
}

class _AddEditStoreProductScreenState extends State<AddEditStoreProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final SellerService _sellerService = SellerService();
  final StoreService _storeService = StoreService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  int? _selectedCategoryId;
  List<StoreCategory> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  File? _imageFile;

  static const Color dharttiGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?['name']?.toString() ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: p?['stock_quantity']?.toString() ?? '10');
    _descriptionController = TextEditingController(text: p?['description']?.toString() ?? '');

    if (p?['category_id'] != null) {
      _selectedCategoryId = int.tryParse(p!['category_id'].toString());
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await _storeService.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: dharttiGreen),
                title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: dharttiGreen),
                title: Text('Take a Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final desc = _descriptionController.text.trim();

    Map<String, dynamic> result;
    if (widget.productToEdit != null) {
      final id = int.tryParse(widget.productToEdit!['id'].toString()) ?? 0;
      result = await _sellerService.updateStoreProduct(
        id: id,
        name: name,
        categoryId: _selectedCategoryId!,
        price: price,
        stockQuantity: stock,
        description: desc.isNotEmpty ? desc : null,
        imageFile: _imageFile,
      );
    } else {
      result = await _sellerService.createStoreProduct(
        name: name,
        categoryId: _selectedCategoryId!,
        price: price,
        stockQuantity: stock,
        description: desc.isNotEmpty ? desc : null,
        imageFile: _imageFile,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Product saved successfully!'),
          backgroundColor: dharttiGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to save product'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final existingImageUrl = widget.productToEdit?['image_url'] ?? widget.productToEdit?['image_path'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Store Product' : 'Add New Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: dharttiGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Area
              Center(
                child: GestureDetector(
                  onTap: _showImagePickerSheet,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : (existingImageUrl != null && existingImageUrl.toString().isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  existingImageUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                ),
                              )
                            : _buildPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Name
              _buildLabel('Product Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration('e.g. Bestway Cement 50kg, Deformed Steel Bars', Icons.inventory_2_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter product name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildLabel('Store Category *'),
              const SizedBox(height: 6),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
                  : DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      decoration: _inputDecoration('Select Category', Icons.category_outlined),
                      items: _categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
              const SizedBox(height: 16),

              // Price & Stock Grid
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Price (PKR) *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecoration('e.g. 1500', Icons.payments_outlined),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(val.trim()) == null) return 'Invalid price';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stock Quantity *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: _inputDecoration('e.g. 50', Icons.format_list_numbered_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter stock';
                            if (int.tryParse(val.trim()) == null) return 'Invalid stock';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Product Description (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration('Specifications, warranty, delivery instructions...', Icons.description_outlined),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(
                          isEditing ? 'Save Product Changes' : 'Publish Product to Store',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: dharttiGreen.withOpacity(0.7)),
        const SizedBox(height: 8),
        Text(
          'Tap to Upload Product Photo',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: dharttiGreen,
          ),
        ),
        Text(
          'JPEG, PNG or WEBP (Max 5MB)',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: dharttiGreen, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
    );
  }
}
