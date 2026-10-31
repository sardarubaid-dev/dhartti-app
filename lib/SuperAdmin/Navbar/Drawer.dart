import 'package:dhartti/SuperAdmin/BlogAdmin/BlogManagement.dart';
import 'package:dhartti/SuperAdmin/CostCalculation/ConstructionCostListScreen.dart';
import 'package:dhartti/SuperAdminPanel/FetchBlog.dart';
import 'package:dhartti/SuperAdminPanel/FetchContact.dart';
import 'package:dhartti/SuperAdminPanel/FetchProject.dart';
import 'package:dhartti/SuperAdminPanel/FetchProperty.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperAdminDrawer extends StatelessWidget {
  final AuthService _authService = AuthService();
  Future<String> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('name') ?? 'John Doe'; // Default if not found
    return username;
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, // Header background color
            ),
            child: FutureBuilder<String>(
              future: _getUsername(), // Fetch the username
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.green, // Green loading indicator
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading user data',
                      style: TextStyle(
                        color: Colors.black, // Black text color
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                String username = snapshot.data ?? 'Guest'; // Default username if data is null

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                  mainAxisAlignment: MainAxisAlignment.start, // Align content to the start
                  children: [
                    // Logo Image aligned to the start
                    Image.asset(
                      'assets/images/nlogo.png', // Replace with your logo asset
                      height: 50, // Adjusted image height
                      width: 180, // Adjusted image width
                    ),
                    SizedBox(height: 10), // Space between logo and username

                    // Username text aligned to the left with added margin
                    Padding(
                      padding: const EdgeInsets.only(left: 10), // Added left margin for text
                      child: Text(
                        username, // Display the username
                        style: TextStyle(
                          color: Colors.black, // Black text color
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 5), // Space between username and "Admin Panel"

                    // "Admin Panel" link with green color and underline
                    Padding(
                      padding: const EdgeInsets.only(left: 10), // Added left margin for text
                      child: GestureDetector(
                        onTap: () {
                          // Implement Admin Panel functionality here
                          print('Admin');
                        },
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.7), // Green color with opacity
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline, // Underline the text
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.green),
            title: const Text('Dashboard'),
            onTap: () {
              // Navigate to Dashboard
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Cost Calculation Tool Data',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConstructionCostListScreen()),
              );               },
          ),
          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Add Blog',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddBlogPage()),
              );               },
          ),
          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Fetch Blog',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DharttiSuperAdminPanelblog()),
              );               },
          ),
          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Fetch Project Data',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProjectListScreenSuperAdmin()),
              );               },
          ),

          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Fetch Property Data',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PropertyListScreenSuperAdmin()),
              );               },
          ),


          ListTile(
            leading: Icon(Icons.business, color: Colors.green), // White icon
            title: Text(
              'Fetch Comtact Data',
              style: TextStyle(color: Colors.black), // White text color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DharttiSuperAdminPanelContact()),
              );               },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.green),
            title: const Text('Home'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BottomNavBarScreen()),
              );               },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _authService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
