import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Model/Blog.dart';
import 'package:dhartti/SuperAdmin/Navbar/Drawer.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/service/blog_service.dart';
import 'package:flutter/material.dart';

class DharttiSuperAdminPanelblog extends StatefulWidget {
  const DharttiSuperAdminPanelblog({super.key});

  @override
  State<DharttiSuperAdminPanelblog> createState() => _DharttiSuperAdminPanelblogState();
}

class _DharttiSuperAdminPanelblogState extends State<DharttiSuperAdminPanelblog> {
  late Future<List<Blog>> blogs;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    blogs = BlogService().fetchBlogs(); // Fetch blogs from the API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Super Admin Blog Panel',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout(); // Call logout method
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false, // Remove all routes from the stack
              );
            },
          ),
        ],
      ),
      drawer: SuperAdminDrawer(), // Pass username to drawer
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.greenAccent, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Blog Management',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Manage all your blogs efficiently',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar (Optional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search blogs...',
                  prefixIcon: Icon(Icons.search, color: Colors.indigo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Blog List
            FutureBuilder<List<Blog>>(
              future: blogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  );
                } else if (snapshot.hasData) {
                  List<Blog> blogs = snapshot.data!;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid layout
                      int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.8, // Adjust card aspect ratio
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: blogs.length,
                        itemBuilder: (context, index) {
                          Blog blog = blogs[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to blog details page
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => BlogDetailsPage(blog: blog)));
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Blog Images (All 4 images)
                                      _buildBlogImages(blog),
                                      const SizedBox(height: 10),

                                      // Blog Details
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Blog Heading
                                            Text(
                                              blog.blogHeading1 ?? 'No Heading',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),

                                            // Blog Description
                                            Text(
                                              blog.blogDescription1 ?? 'No Description',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),

                                            // Blog Quote (Optional)
                                            if (blog.blogQuote != null && blog.blogQuote!.isNotEmpty)
                                              Text(
                                                '"${blog.blogQuote}"',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.blueAccent,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                            // Author Name (Optional)
                                            if (blog.blogQuoteByPerson != null && blog.blogQuoteByPerson!.isNotEmpty)
                                              Text(
                                                '- ${blog.blogQuoteByPerson}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Edit and Delete Icons
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            // Add edit functionality
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Add delete functionality
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text(
                      'No blogs found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new blog functionality
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget to display all blog images
  Widget _buildBlogImages(Blog blog) {
    List<String?> images = [
      blog.blogImage1,
      // blog.blogImage2,
      // blog.blogImage3,
      // blog.blogImage4,
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          String? imageUrl = images[index];
          if (imageUrl == null || imageUrl.isEmpty) {
            return Container(); // Skip empty images
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
