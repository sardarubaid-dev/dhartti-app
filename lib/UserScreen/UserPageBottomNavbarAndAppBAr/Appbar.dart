import 'package:dhartti/UserScreen/NotificationScreen.dart';
import 'package:dhartti/UserScreen/Chat/ChatInboxScreen.dart';
import 'package:dhartti/UserScreen/UpgradeRoleScreen.dart';
import 'package:dhartti/UserScreen/LoanTool/fetch.dart';
import 'package:dhartti/UserScreen/LoanTool/SchemeApplicationsScreen.dart';
import 'package:dhartti/UserScreen/LoanTool.dart';
import 'package:dhartti/area_converter.dart';
import 'package:dhartti/area_guide.dart';
import 'package:dhartti/UserScreen/PropertyTrend.dart';

import 'package:dhartti/StaticPages/FAQScreen.dart';
import 'package:dhartti/StaticPages/PrivacyPolicyScreen.dart';
import 'package:dhartti/StaticPages/ServicesScreen.dart';
import 'package:dhartti/StaticPages/PricingScreen.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/About.dart';
import 'package:dhartti/ContactUs.dart';
import 'package:dhartti/UserDashboard/UserDashboard.dart';
import 'package:dhartti/UserScreen/DharttiBlog.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/UserScreen/userProfile.dart';
import 'package:dhartti/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  Future<Map<String, String?>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    var roleId = prefs.getString('roleId') ?? '1';
    final token = prefs.getString('token');
    if (token != null && roleId == '1') {
      try {
        await _authService.getUpgradeStatus();
        roleId = prefs.getString('roleId') ?? roleId;
      } catch (_) {}
    }
    return {
      'name': prefs.getString('name') ?? 'Guest',
      'roleId': roleId,
      'token': token,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        bool isGuest = snapshot.data?['token'] == null;
        String username = snapshot.data?['name'] ?? 'Guest';

        return Drawer(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimalist Premium Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Row(
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Color(0xFF108224).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, size: 30, color: Color(0xFF108224)),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Georgia',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              isGuest ? 'Welcome to Dhartti' : 'User Account',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                ),
                SizedBox(height: 10),
                
                // Scrollable List
                Expanded(
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildDrawerItem(Icons.home_outlined, 'Home', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavBarScreen()))),
                      _buildDrawerItem(Icons.maps_home_work_outlined, 'Properties', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavBarScreen(initialIndex: 1)))),
                      _buildDrawerItem(Icons.shopping_bag_outlined, 'Shop', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavBarScreen(initialIndex: 2)))),
                      
                      if (!isGuest) ...[
                        if (snapshot.data?['roleId'] == '2') ...[
                          _buildDrawerItem(Icons.add_home_outlined, 'Add Property', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddPropertyScreen()))),
                          _buildDrawerItem(Icons.list_alt_outlined, 'Seller Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDashboardScreen()))),
                          _buildDrawerItem(Icons.account_balance_outlined, 'My Schemes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeListScreen(showUserSchemesOnly: true)))),
                          _buildDrawerItem(Icons.assignment_outlined, 'Scheme Applications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen()))),
                        ] else if (snapshot.data?['roleId'] == '3') ...[
                          _buildDrawerItem(Icons.construction_outlined, 'Contractor Hub', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDashboardScreen()))),
                          _buildDrawerItem(Icons.assignment_outlined, 'My Applications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen()))),
                        ] else ...[
                          _buildDrawerItem(Icons.assignment_outlined, 'My Applications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeApplicationsScreen()))),
                          _buildDrawerItem(Icons.workspace_premium_outlined, 'Upgrade Account', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeRoleScreen()))),
                        ],
                        _buildDrawerItem(Icons.favorite_outline, 'Favourites', () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavouriteScreen()))),
                        _buildDrawerItem(Icons.notifications_outlined, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                        _buildDrawerItem(Icons.forum_outlined, 'Messages / Chat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatInboxScreen()))),
                        _buildDrawerItem(Icons.person_outline, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()))),
                      ],
                      _buildDrawerItem(Icons.calculate_outlined, 'Home Loan Calculator', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemesToolScreen()))),
                      _buildDrawerItem(Icons.straighten_outlined, 'Area Unit Converter', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaConverterScreen()))),
                      _buildDrawerItem(Icons.explore_outlined, 'Area & Society Guides', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AreaGuideScreen()))),
                      _buildDrawerItem(Icons.trending_up_outlined, 'Property Market Trends', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PropertyTrend()))),
                      _buildDrawerItem(Icons.account_balance_outlined, 'Schemes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchemeListScreen(showUserSchemesOnly: false)))),
                      
                      SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                      ),
                      SizedBox(height: 10),
                      
                      _buildDrawerItem(Icons.article_outlined, 'Blog', () => Navigator.push(context, MaterialPageRoute(builder: (_) => Dharttiblog()))),
                      _buildDrawerItem(Icons.info_outline, 'About Us', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage()))),
                      _buildDrawerItem(Icons.contact_mail_outlined, 'Contact Us', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactPage()))),
                      _buildDrawerItem(Icons.miscellaneous_services_outlined, 'Services', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesScreen()))),
                      _buildDrawerItem(Icons.price_check_outlined, 'Pricing', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PricingScreen()))),
                      _buildDrawerItem(Icons.question_answer_outlined, 'FAQ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => FAQScreen()))),
                      _buildDrawerItem(Icons.privacy_tip_outlined, 'Privacy Policy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()))),
                    ],
                  ),
                ),
                
                // Logout / Login button pinned at the bottom
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, -5))
                    ],
                  ),
                  child: _buildDrawerItem(
                    isGuest ? Icons.login : Icons.logout,
                    isGuest ? 'Login' : 'Logout',
                    () async {
                      if (!isGuest) {
                        await _authService.logout();
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    isLogout: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    Color itemColor = isLogout ? Colors.red.shade700 : Colors.black87;
    Color iconColor = isLogout ? Colors.red.shade700 : Color(0xFF108224);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: itemColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.1),
          hoverColor: iconColor.withOpacity(0.05),
        ),
      ),
    );
  }
}