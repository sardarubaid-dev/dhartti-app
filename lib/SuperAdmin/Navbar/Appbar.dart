import 'package:flutter/material.dart';

class SuperAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed; // Callback for burger icon
  final VoidCallback? onLogoutPressed; // Callback for logout icon

  const SuperAdminAppBar({
    super.key,
    this.onMenuPressed,
    this.onLogoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Center(
        child: Image.asset(
          'assets/images/nlogo.png', // Replace with your logo
          height: 40, // Adjust height as needed
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: onLogoutPressed, // Logout functionality
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black), // Drawer icon
        onPressed: onMenuPressed, // Open drawer
      ),
      backgroundColor: Colors.white, // White background
      elevation: 0, // Remove shadow
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
