import 'package:dhartti/SuperAdmin/Navbar/Searchbar.dart';
import 'package:dhartti/SuperAdmin/Propertycard.dart';
import 'package:flutter/material.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/SuperAdmin/Navbar/Appbar.dart';
import 'package:dhartti/SuperAdmin/Navbar/Drawer.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:dhartti/SuperAdmin/Navbar/BottomNavbar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dhartti/service/property_service.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String username = 'Super Admin';
  final AuthService _authService = AuthService();
  final PropertyService _propertyService = PropertyService();
  final ProjectService _projectService = ProjectService();

  // Dashboard metrics
  int totalUsers = 0;
  int totalProperties = 0;
  int totalProjects = 0;
  int totalFeatures = 0;
  bool isLoading = true;

  final List<String> featuredProperties = [
    'assets/images/contact-us-banner.jpg',
    'assets/images/blogbg.jpg',
    'assets/images/banner.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('name') ?? 'Super Admin';
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _propertyService.fetchProperties(),              // returns List
        _projectService.fetchProjectsBySuperAdmin(),     // returns List
        _authService.fetchTotalUsers(),                  // returns int
      ]);

      // 👇 Explicitly cast results[0] and results[1] as List
      final List properties = results[0] as List;
      final List projects = results[1] as List;
      final int users = results[2] as int;

      setState(() {
        totalProperties = properties.length;
        totalProjects = projects.length;
        totalUsers = users;
        totalFeatures = 25;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data')),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Center(
          child: Image.asset(
            'assets/images/nlogo.png',
            height: 40,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: SuperAdminDrawer(),
      body: _buildBody(),
      bottomNavigationBar: SuperAdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomSearchBar(),
          const SizedBox(height: 20),
          _buildFeaturedProperties(),
          const SizedBox(height: 20),
          Text(
            'Welcome, $username!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          _buildDashboardCards(),
          const SizedBox(height: 20),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildFeaturedProperties() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: featuredProperties.map((imageUrl) {
        return Container(
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(imageUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDashboardCards() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCard('Total Users', totalUsers.toString(), Icons.people),
        _buildCard('Total Properties', totalProperties.toString(), Icons.home_work),
        _buildCard('Total Projects', totalProjects.toString(), Icons.business),
        _buildCard('Total Features', totalFeatures.toString(), Icons.star),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.notifications, color: Colors.green),
              title: Text('Activity ${index + 1}'),
              subtitle: const Text('Details of the activity'),
              trailing: const Icon(Icons.arrow_forward, color: Colors.green),
            );
          },
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }
}
