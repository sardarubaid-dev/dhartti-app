import 'package:dhartti/UserDashboard/Inquiries/SellerInquiriesScreen.dart';
import 'package:flutter/material.dart';
import 'package:dhartti/UserDashboard/UserDashboard.dart';
import 'package:dhartti/UserDashboard/UserPropertyScreen/UserPropertyListScreen.dart';
import 'package:dhartti/UserDashboard/UserProjectScreen/UserProjectListScreen.dart';
import 'package:dhartti/UserScreen/AllProject.dart';
import 'package:dhartti/UserScreen/VentureFetch.dart';
import 'package:dhartti/UserDashboard/Bids/MyBidsTrackingScreen.dart';
import 'package:dhartti/UserDashboard/StoreAdmin/SellerStoreDashboardScreen.dart';

class UserAdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isContractor;

  const UserAdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isContractor = false,
  });

  void _navigateToScreen(BuildContext context, int index) {
    Widget destination;

    if (isContractor) {
      switch (index) {
        case 0:
          destination = const UserDashboardScreen();
          break;
        case 1:
          destination = const ProjectListScreens();
          break;
        case 2:
          destination = const JoinVentureListScreen();
          break;
        case 3:
          destination = const MyBidsTrackingScreen();
          break;
        case 4:
          destination = const SellerStoreDashboardScreen();
          break;
        default:
          return;
      }
    } else {
      switch (index) {
        case 0:
          destination = const UserDashboardScreen();
          break;
        case 1:
          destination = UserPanelPropertyListScreen();
          break;
        case 2:
          destination = UserPanelProjectListScreen();
          break;
        case 3:
          destination = const SellerInquiriesScreen();
          break;
        case 4:
          destination = const SellerStoreDashboardScreen();
          break;
        default:
          return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );

    onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = isContractor
        ? [
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.engineering_rounded,
                isSelected: currentIndex == 0,
              ),
              label: 'Hub',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.apartment_rounded,
                isSelected: currentIndex == 1,
              ),
              label: 'Tenders',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.handshake_rounded,
                isSelected: currentIndex == 2,
              ),
              label: 'Ventures',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.track_changes_rounded,
                isSelected: currentIndex == 3,
              ),
              label: 'My Bids',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.storefront_rounded,
                isSelected: currentIndex == 4,
              ),
              label: 'Store',
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.home_rounded,
                isSelected: currentIndex == 0,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.domain_rounded,
                isSelected: currentIndex == 1,
              ),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.business_rounded,
                isSelected: currentIndex == 2,
              ),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.mail_rounded,
                isSelected: currentIndex == 3,
              ),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.storefront_rounded,
                isSelected: currentIndex == 4,
              ),
              label: 'Store',
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isContractor
              ? [const Color(0xFF92400E), const Color(0xFFB45309)]
              : [const Color(0xFF0F6E20), const Color(0xFF108224)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: (index) => _navigateToScreen(context, index),
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.65),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: items,
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _AnimatedNavIcon({
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
      child: Icon(
        icon,
        size: isSelected ? 24 : 21,
      ),
    );
  }
}
