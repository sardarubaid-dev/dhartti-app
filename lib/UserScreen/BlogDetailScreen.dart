import 'dart:async';
import 'package:dhartti/Model/Blog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;

  const BlogDetailScreen({Key? key, required this.blog}) : super(key: key);

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  static const Color dharttiGreen = Color(0xFF108224);
  bool _isLiked = false;
  int _activeImageIndex = 0;
  late PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    final imagesCount = widget.blog.allImages.length;
    if (imagesCount <= 1) return;
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextIdx = (_activeImageIndex + 1) % imagesCount;
      _pageController.animateToPage(
        nextIdx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blog = widget.blog;
    final images = blog.allImages;
    final dateStr = blog.createdAt != null
        ? DateFormat('MMMM dd, yyyy').format(blog.createdAt!)
        : 'Recent Article';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF9),
      body: CustomScrollView(
        slivers: [
          // Collapsible Hero App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: dharttiGreen,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.redAccent : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  setState(() => _isLiked = !_isLiked);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isLiked ? 'Article saved to favorites!' : 'Removed from favorites'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: dharttiGreen,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing blog article...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: dharttiGreen,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // PageView Image Carousel
                  if (images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _activeImageIndex = i),
                      itemBuilder: (context, idx) {
                        return Image.network(
                          images[idx],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackHero(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(color: dharttiGreen, strokeWidth: 2),
                              ),
                            );
                          },
                        );
                      },
                    )
                  else
                    _buildFallbackHero(),

                  // Gradient shadow - wrapped in IgnorePointer to allow gestures to reach PageView
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Left navigation chevron
                  if (images.length > 1)
                    Positioned(
                      left: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _startAutoSlide();
                              final prev = (_activeImageIndex - 1 + images.length) % images.length;
                              _pageController.animateToPage(
                                prev,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Right navigation chevron
                  if (images.length > 1)
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              _startAutoSlide();
                              final next = (_activeImageIndex + 1) % images.length;
                              _pageController.animateToPage(
                                next,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Image counter chip
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${_activeImageIndex + 1}/${images.length}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Interactive Image dots indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => GestureDetector(
                            onTap: () {
                              _startAutoSlide();
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _activeImageIndex == i ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _activeImageIndex == i ? dharttiGreen : Colors.white.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Article Body Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: blog.tagsList.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dharttiGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: dharttiGreen.withOpacity(0.2)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dharttiGreen,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Main Title (Heading 1)
                  Text(
                    blog.blogHeading1.isNotEmpty ? blog.blogHeading1 : 'Dhartti Property Insight',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Row: Author & Date & Read Time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: dharttiGreen.withOpacity(0.15),
                          child: const Icon(Icons.person, color: dharttiGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blog.blogQuoteByPerson.isNotEmpty ? blog.blogQuoteByPerson : 'Dhartti Research Team',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
                                  Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${blog.readTimeMinutes} min read',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Paragraph 1
                  if (blog.blogDescription1.isNotEmpty) ...[
                    _buildParagraph(blog.blogDescription1),
                    const SizedBox(height: 16),
                  ],

                  // Quote Block (if exists)
                  if (blog.blogQuote.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dharttiGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: dharttiGreen, width: 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, color: dharttiGreen, size: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  blog.blogQuote,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF1E3A1E),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (blog.blogQuoteByPerson.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '— ${blog.blogQuoteByPerson}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dharttiGreen,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section 2: Heading 2 & Descriptions 2 & 3
                  if (blog.blogHeading2.isNotEmpty) ...[
                    _buildSubHeading(blog.blogHeading2),
                    const SizedBox(height: 10),
                  ],
                  if (blog.blogDescription2.isNotEmpty) ...[
                    _buildParagraph(blog.blogDescription2),
                    const SizedBox(height: 14),
                  ],
                  if (blog.blogDescription3.isNotEmpty) ...[
                    _buildParagraph(blog.blogDescription3),
                    const SizedBox(height: 16),
                  ],

                  // Inline Secondary Image
                  if (blog.blogImage2 != null && blog.blogImage2!.trim().isNotEmpty) ...[
                    _buildInlineImage(blog.blogImage2!),
                    const SizedBox(height: 20),
                  ],

                  // Section 3: Heading 3 & Descriptions 4 & 5
                  if (blog.blogHeading3.isNotEmpty) ...[
                    _buildSubHeading(blog.blogHeading3),
                    const SizedBox(height: 10),
                  ],
                  if (blog.blogDescription4.isNotEmpty) ...[
                    _buildParagraph(blog.blogDescription4),
                    const SizedBox(height: 14),
                  ],
                  if (blog.blogDescription5.isNotEmpty) ...[
                    _buildParagraph(blog.blogDescription5),
                    const SizedBox(height: 20),
                  ],

                  // Gallery of remaining images (3 and 4)
                  if ((blog.blogImage3 != null && blog.blogImage3!.isNotEmpty) ||
                      (blog.blogImage4 != null && blog.blogImage4!.isNotEmpty)) ...[
                    Text(
                      'Photo Gallery',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (blog.blogImage3 != null && blog.blogImage3!.isNotEmpty)
                          Expanded(child: _buildInlineImage(blog.blogImage3!)),
                        if (blog.blogImage3 != null &&
                            blog.blogImage3!.isNotEmpty &&
                            blog.blogImage4 != null &&
                            blog.blogImage4!.isNotEmpty)
                          const SizedBox(width: 10),
                        if (blog.blogImage4 != null && blog.blogImage4!.isNotEmpty)
                          Expanded(child: _buildInlineImage(blog.blogImage4!)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom Engagement Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [dharttiGreen.withOpacity(0.08), dharttiGreen.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dharttiGreen.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Enjoyed this read?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share real estate insights with friends and colleagues.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                          label: Text(
                            'Explore More Blogs',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dharttiGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHero() {
    return Container(
      color: const Color(0xFF1E3A1E),
      child: const Center(
        child: Icon(Icons.newspaper, color: Colors.white38, size: 64),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        height: 1.7,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildSubHeading(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildInlineImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(color: dharttiGreen, strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 140,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
          ),
        ),
      ),
    );
  }
}
