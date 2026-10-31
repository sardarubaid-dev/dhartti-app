import 'package:dhartti/UserScreen/userProfile.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/HomePage.dart';
import 'package:dhartti/UserScreen/Store/ShopScreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/propertyListScreen.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/Appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';

// Main Screen with Bottom Navigation
class BottomNavBarScreen extends StatefulWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final int initialIndex;
  final String? initialCity;
  final String? initialPurpose;
  final String? initialPropertyType;
  final String? initialBeds;
  final String? initialBaths;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final double? initialMinArea;
  final double? initialMaxArea;
  final String? initialKeyword;

  const BottomNavBarScreen({
    Key? key,
    this.initialIndex = 0,
    this.initialCity,
    this.initialPurpose,
    this.initialPropertyType,
    this.initialBeds,
    this.initialBaths,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinArea,
    this.initialMaxArea,
    this.initialKeyword,
  }) : super(key: key);

  @override
  _BottomNavBarScreenState createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  late int _selectedIndex;
  bool isGuest = true;

  @override
  void initState() {
    super.initState();
    BottomNavBarScreen.scaffoldKey = GlobalKey<ScaffoldState>();
    _selectedIndex = widget.initialIndex;
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getString('token') == null;
    });
  }

  void _onItemTapped(int index) {
    if (isGuest && (index == 3 || index == 4)) {
      _showLoginDialog();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Login Required"),
        content: Text("You need to login to access this feature. Do you want to login now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: Text("Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Widget> get _pages => [
    HomePage(),
    PropertyListScreen(
      initialCity: widget.initialCity,
      initialPurpose: widget.initialPurpose,
      initialPropertyType: widget.initialPropertyType,
      initialBeds: widget.initialBeds,
      initialBaths: widget.initialBaths,
      initialMinPrice: widget.initialMinPrice,
      initialMaxPrice: widget.initialMaxPrice,
      initialMinArea: widget.initialMinArea,
      initialMaxArea: widget.initialMaxArea,
      initialKeyword: widget.initialKeyword,
    ),
    ShopScreen(),
    FavouriteScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: BottomNavBarScreen.scaffoldKey,
      drawer: DrawerScreen(),
      extendBody: true, // Allows body to extend behind the navbar
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: _pages[_selectedIndex], // Show the selected screen with animation
          ),
          // Floating Pill Bottom Navigation Bar (Responsive Hearthline Style)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 8
                : 16,
            left: 16,
            right: 16,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(child: Center(child: _buildNavItem(Icons.home_outlined, Icons.home, 0))),
                  Expanded(child: Center(child: _buildNavItem(Icons.maps_home_work_outlined, Icons.maps_home_work, 1))),
                  Expanded(child: Center(child: _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 2))),
                  Expanded(child: Center(child: _buildNavItem(Icons.favorite_outline, Icons.favorite, 3))),
                  Expanded(child: Center(child: _buildNavItem(Icons.person_outline, Icons.person, 4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF108224) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 23,
        ),
      ),
    );
  }
}
