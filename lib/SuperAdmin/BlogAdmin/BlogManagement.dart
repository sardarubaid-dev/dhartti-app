import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dhartti/service/blog_service.dart';

class AddBlogPage extends StatefulWidget {
  @override
  _AddBlogPageState createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final BlogService _blogService = BlogService();
  final ImagePicker _picker = ImagePicker();

  // Controllers for form fields
  final TextEditingController _heading1Controller = TextEditingController();
  final TextEditingController _heading2Controller = TextEditingController();
  final TextEditingController _heading3Controller = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _description1Controller = TextEditingController();
  final TextEditingController _description2Controller = TextEditingController();
  final TextEditingController _description3Controller = TextEditingController();
  final TextEditingController _description4Controller = TextEditingController();
  final TextEditingController _description5Controller = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _quoteByPersonController = TextEditingController();

  // Image files
  File? _image1;
  File? _image2;
  File? _image3;
  File? _image4;

  bool _isLoading = false;

  @override
  void dispose() {
    _heading1Controller.dispose();
    _heading2Controller.dispose();
    _heading3Controller.dispose();
    _tagController.dispose();
    _description1Controller.dispose();
    _description2Controller.dispose();
    _description3Controller.dispose();
    _description4Controller.dispose();
    _description5Controller.dispose();
    _quoteController.dispose();
    _quoteByPersonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageNumber) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        switch (imageNumber) {
          case 1:
            _image1 = File(pickedFile.path);
            break;
          case 2:
            _image2 = File(pickedFile.path);
            break;
          case 3:
            _image3 = File(pickedFile.path);
            break;
          case 4:
            _image4 = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          }
              : null,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.green.shade600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines == 1 ? 0 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: imageFile == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to add image',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Add New Blog',
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
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blog Images Section
              _buildSectionHeader('Blog Images'),
              SizedBox(height: 16),
              _buildImagePicker(
                label: 'Primary Image',
                imageFile: _image1,
                onPressed: () => _pickImage(1),
              ),
              SizedBox(height: 16),
              _buildImagePicker(
                label: 'Secondary Image 1',
                imageFile: _image2,
                onPressed: () => _pickImage(2),
              ),
              SizedBox(height: 16),
              _buildImagePicker(
                label: 'Secondary Image 2',
                imageFile: _image3,
                onPressed: () => _pickImage(3),
              ),
              SizedBox(height: 16),
              _buildImagePicker(
                label: 'Secondary Image 3',
                imageFile: _image4,
                onPressed: () => _pickImage(4),
              ),
              SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _heading1Controller,
                label: 'Blog Heading 1',
                hint: 'Enter main heading',
                icon: Icons.title,
                isRequired: true,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _heading2Controller,
                label: 'Blog Heading 2',
                hint: 'Enter secondary heading',
                icon: Icons.title,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _heading3Controller,
                label: 'Blog Heading 3',
                hint: 'Enter tertiary heading',
                icon: Icons.title,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _tagController,
                label: 'Blog Tag',
                hint: 'Enter blog tag/category',
                icon: Icons.tag,
              ),
              SizedBox(height: 24),

              // Content Section
              _buildSectionHeader('Content'),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _description1Controller,
                label: 'Blog Description 1',
                hint: 'Enter main description',
                icon: Icons.description,
                isRequired: true,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _description2Controller,
                label: 'Blog Description 2',
                hint: 'Enter secondary description',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _description3Controller,
                label: 'Blog Description 3',
                hint: 'Enter additional description',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _description4Controller,
                label: 'Blog Description 4',
                hint: 'Enter additional description',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _description5Controller,
                label: 'Blog Description 5',
                hint: 'Enter additional description',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 24),

              // Featured Quote Section
              _buildSectionHeader('Featured Quote'),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _quoteController,
                label: 'Blog Quote',
                hint: 'Enter inspirational quote',
                icon: Icons.format_quote,
                maxLines: 2,
              ),
              SizedBox(height: 16),
              _buildTextInputField(
                controller: _quoteByPersonController,
                label: 'Quote By',
                hint: 'Enter quote author',
                icon: Icons.person,
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.green.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Publish Blog',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare the blog data
      final blogData = {
        'Blog_heading_1': _heading1Controller.text,
        'Blog_heading_2': _heading2Controller.text,
        'Blog_heading_3': _heading3Controller.text,
        'Blog_tag': _tagController.text,
        'Blog_description_1': _description1Controller.text,
        'Blog_description_2': _description2Controller.text,
        'Blog_description_3': _description3Controller.text,
        'Blog_description_4': _description4Controller.text,
        'Blog_description_5': _description5Controller.text,
        'Blog_quote': _quoteController.text,
        'Blog_quote_by_person': _quoteByPersonController.text,
      };

      // Submit the form data
      await _blogService.createBlog(blogData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blog published successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Clear all form fields
      _heading1Controller.clear();
      _heading2Controller.clear();
      _heading3Controller.clear();
      _tagController.clear();
      _description1Controller.clear();
      _description2Controller.clear();
      _description3Controller.clear();
      _description4Controller.clear();
      _description5Controller.clear();
      _quoteController.clear();
      _quoteByPersonController.clear();
      setState(() {
        _image1 = null;
        _image2 = null;
        _image3 = null;
        _image4 = null;
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
