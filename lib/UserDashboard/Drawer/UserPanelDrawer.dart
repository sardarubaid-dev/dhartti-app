import 'package:dhartti/UserScreen/Chat/ChatInboxScreen.dart';
import 'package:dhartti/UserScreen/PropertyScreen/add-property.dart';
import 'package:flutter/material.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dhartti/UserDashboard/UserDashboard.dart';
import 'package:dhartti/UserDashboard/UserProjectScreen/UserProjectListScreen.dart';
import 'package:dhartti/UserDashboard/UserPropertyScreen/UserPropertyListScreen.dart';
import 'package:dhartti/UserDashboard/Feature/service.dart';
import 'package:dhartti/UserScreen/ProjectScreen/projectmanagementscreen.dart';
import 'package:dhartti/UserScreen/LoanTool/fetch.dart';
import 'package:dhartti/UserScreen/LoanTool/add.dart';
import 'package:dhartti/UserScreen/LoanTool/SchemeApplicationsScreen.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';
import 'package:dhartti/service/auth_service.dart';

import 'package:dhartti/UserDashboard/Inquiries/SellerInquiriesScreen.dart';
import 'package:dhartti/UserDashboard/Reviews/SellerReviewsScreen.dart';
import 'package:dhartti/UserDashboard/StoreAdmin/SellerStoreDashboardScreen.dart';
import 'package:dhartti/UserDashboard/Bids/MyBidsTrackingScreen.dart';
import 'package:dhartti/UserScreen/userProfile.dart';
import 'package:dhartti/UserScreen/Favourite.dart';
import 'package:dhartti/UserScreen/AllProject.dart';
import 'package:dhartti/UserScreen/VentureFetch.dart';
import 'package:dhartti/UserScreen/DharttiBlog.dart';
import 'package:dhartti/SuperAdmin/BlogAdmin/BlogManagement.dart';
import 'package:dhartti/UserScreen/Store/CartScreen.dart';
import 'package:dhartti/UserScreen/Store/MyOrdersScreen.dart';
import 'package:dhartti/UserScreen/NotificationScreen.dart';
import 'package:dhartti/CostCalculatorScreen.dart';
import 'package:dhartti/UserScreen/RoleUpgradeFormScreen.dart';
import 'package:dhartti/UserScreen/UpgradeRoleScreen.dart';

class UserAdminDrawer extends StatelessWidget {
  UserAdminDrawer({super.key});

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    var roleId = prefs.getString('roleId') ?? '1';
    Map<String, dynamic>? pendingReq;
    if (roleId == '1') {
      try {
        final statusRes = await _authService.getUpgradeStatus();
        if (statusRes['has_request'] == true && statusRes['request'] != null) {
          pendingReq = statusRes['request'];
        }
        roleId = prefs.getString('roleId') ?? roleId;
      } catch (_) {}
    }
    return {
      'name': prefs.getString('name') ?? 'User',
      'roleId': roleId,
      'pendingRequest': pendingReq,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final userInfo = snapshot.data ?? {'name': 'User', 'roleId': '1'};
          final username = userInfo['name'] ?? 'User';
          final roleId = userInfo['roleId'] ?? '1';
          final pendingRequest = userInfo['pendingRequest'] as Map<String, dynamic>?;
          final isPending = pendingRequest != null && pendingRequest['status'] == 'pending';
          final isContractor = roleId == '3';
          final isBuyer = roleId == '1';
          final isSeller = roleId == '2';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // ==== Drawer Header with username, role badge, and logo ====
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/nlogo.png', height: 42, width: 155),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF108224),
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  Text(
                                    isContractor ? 'Certified Contractor' : (isBuyer ? 'Verified Buyer' : 'Verified Seller'),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isContractor
                                    ? Colors.orange.shade50
                                    : (isBuyer ? Colors.blueGrey.shade50 : const Color(0xFFE8F5E9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isContractor
                                      ? Colors.orange.shade200
                                      : (isBuyer ? Colors.blueGrey.shade200 : const Color(0xFFA5D6A7)),
                                ),
                              ),
                              child: Text(
                                isContractor ? 'Contractor' : (isBuyer ? 'Buyer' : 'Seller'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isContractor
                                      ? Colors.orange.shade900
                                      : (isBuyer ? Colors.blueGrey.shade800 : const Color(0xFF1B5E20)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==== Menu Items ====
              _buildTile(context, icon: Icons.dashboard_outlined, title: 'Dashboards', screen: const UserDashboardScreen()),
              _buildTile(context, icon: Icons.notifications_none_rounded, title: 'Notifications', screen: const NotificationScreen()),
              _buildTile(context, icon: Icons.forum_outlined, title: 'Chat / Inbox', screen: const ChatInboxScreen()),
              _buildTile(context, icon: Icons.person_outline, title: 'Profile', screen: const UserProfileScreen()),

              if (isContractor) ...[
                // CONTRACTOR SPECIFIC MENU
                _buildTile(context, icon: Icons.apartment_rounded, title: 'Browse Projects (Bidding)', screen: const ProjectListScreens()),
                _buildTile(context, icon: Icons.handshake_outlined, title: 'Join Ventures (Bidding)', screen: const JoinVentureListScreen()),
                _buildTile(context, icon: Icons.track_changes_outlined, title: 'My Bids (Tracking)', screen: const MyBidsTrackingScreen()),
                _buildTile(context, icon: Icons.calculate_outlined, title: 'Construction Cost Tool', screen: CostCalculatorForm()),
                _buildTile(context, icon: Icons.storefront_outlined, title: 'Store Dashboard', screen: const SellerStoreDashboardScreen()),
                _buildTile(context, icon: Icons.rate_review_outlined, title: 'Reviews', screen: const SellerReviewsScreen()),
                _buildTile(context, icon: Icons.mail_outline_rounded, title: 'Inquiries & Leads', screen: const SellerInquiriesScreen()),
                _buildTile(context, icon: Icons.shopping_cart_outlined, title: 'My Cart', screen: const CartScreen()),
                _buildTile(context, icon: Icons.shopping_bag_outlined, title: 'My Orders', screen: const MyOrdersScreen()),
              ] else if (isBuyer) ...[
                // BUYER SPECIFIC MENU (Upgrade & Tools)
                if (isPending)
                  ListTile(
                    leading: const Icon(Icons.pending_actions, color: Colors.orange),
                    title: const Text('Application Pending (Review)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Role: ${pendingRequest['requested_role']?.toString() == '3' ? 'Contractor' : 'Seller'}', style: const TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UpgradeRoleScreen()),
                      );
                    },
                  )
                else ...[
                  _buildTile(context, icon: Icons.storefront_outlined, title: 'Become a Seller', screen: const RoleUpgradeFormScreen(targetRole: 2)),
                  _buildTile(context, icon: Icons.construction_outlined, title: 'Become a Contractor', screen: const RoleUpgradeFormScreen(targetRole: 3)),
                ],
                _buildTile(context, icon: Icons.favorite_border_rounded, title: 'My Favorite', screen: const FavouriteScreen()),
                _buildTile(context, icon: Icons.apartment_rounded, title: 'Browse Projects', screen: const ProjectListScreens()),
                _buildTile(context, icon: Icons.handshake_outlined, title: 'Joint Ventures', screen: const JoinVentureListScreen()),
                _buildTile(context, icon: Icons.calculate_outlined, title: 'Construction Cost Tool', screen: CostCalculatorForm()),
                _buildTile(context, icon: Icons.article_outlined, title: 'Blogs', screen: const Dharttiblog()),
                _buildTile(context, icon: Icons.shopping_cart_outlined, title: 'My Cart', screen: const CartScreen()),
                _buildTile(context, icon: Icons.shopping_bag_outlined, title: 'My Orders', screen: const MyOrdersScreen()),
              ] else if (isSeller) ...[
                // SELLER SPECIFIC MENU - EXACT MATCH WITH WEB SELLER SIDEBAR
                _buildTile(context, icon: Icons.handshake_outlined, title: 'Join Ventures (Bidding)', screen: const JoinVentureListScreen()),
                _buildTile(context, icon: Icons.track_changes_outlined, title: 'My Bids (Tracking)', screen: const MyBidsTrackingScreen()),
                _buildTile(context, icon: Icons.storefront_outlined, title: 'Store Dashboard', screen: const SellerStoreDashboardScreen()),
                _buildTile(context, icon: Icons.rate_review_outlined, title: 'Reviews', screen: const SellerReviewsScreen()),
                _buildTile(context, icon: Icons.home_work_outlined, title: 'My Properties', screen: UserPanelPropertyListScreen()),
                _buildTile(context, icon: Icons.apartment_outlined, title: 'My Projects', screen: UserPanelProjectListScreen()),
                _buildTile(context, icon: Icons.account_balance_outlined, title: 'My Schemes', screen: const SchemeListScreen()),
                _buildTile(context, icon: Icons.assignment_turned_in_outlined, title: 'Scheme Applications', screen: const SchemeApplicationsScreen()),
                _buildTile(context, icon: Icons.article_outlined, title: 'Blogs', screen: const Dharttiblog()),
                _buildTile(context, icon: Icons.auto_awesome_outlined, title: 'Features', screen: const ServicesScreen()),
                _buildTile(context, icon: Icons.favorite_border_rounded, title: 'My Favorite', screen: const FavouriteScreen()),
                _buildTile(context, icon: Icons.forum_outlined, title: 'Messages / Chat', screen: const ChatInboxScreen()),
                _buildTile(context, icon: Icons.mail_outline_rounded, title: 'Property Inquiries', screen: const SellerInquiriesScreen()),
                _buildTile(context, icon: Icons.add_home_outlined, title: 'Add Property', screen: AddPropertyScreen()),
                _buildTile(context, icon: Icons.note_add_outlined, title: 'Add Scheme', screen: const AddEditSchemeScreen()),
                _buildTile(context, icon: Icons.post_add_outlined, title: 'Add Blog', screen: AddBlogPage()),
                _buildTile(context, icon: Icons.add_business_outlined, title: 'Add Project', screen: AddProjectScreen()),
                _buildTile(context, icon: Icons.shopping_cart_outlined, title: 'My Cart', screen: const CartScreen()),
                _buildTile(context, icon: Icons.shopping_bag_outlined, title: 'My Orders', screen: const MyOrdersScreen()),
              ],

              _buildTile(context, icon: Icons.home_outlined, title: 'Home', screen: BottomNavBarScreen()),

              const Divider(),
              // ==== Logout Button ====
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
          );
        },
      ),
    );
  }

  // ==== Reusable Tile Builder ====
  Widget _buildTile(BuildContext context, {required IconData icon, required String title, required Widget screen}) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1.5),
      leading: Icon(icon, color: Colors.green.shade700, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer smoothly
        if (screen is UserDashboardScreen) {
          // If already on dashboard screen or navigating to it
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        }
      },
    );
  }
}