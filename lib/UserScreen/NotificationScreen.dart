import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/Auth_Screens/register.dart';
import 'package:dhartti/Model/notification_model.dart';
import 'package:dhartti/service/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  bool _isLoading = true;
  bool _isGuest = false;
  List<UserNotificationModel> _notifications = [];
  String _selectedCategory = 'all';

  // Professional slate/neutral theme colors
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color subtleBg = Color(0xFFF8FAFC);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color primaryGreen = Color(0xFF108224);

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All'},
    {'id': 'inquiry', 'label': 'Inquiries'},
    {'id': 'scheme', 'label': 'Schemes & Loans'},
    {'id': 'bid', 'label': 'Bids & Projects'},
    {'id': 'order', 'label': 'Orders'},
    {'id': 'system', 'label': 'System'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService.liveUpdateTrigger.addListener(_onLiveNotificationReceived);
  }

  @override
  void dispose() {
    NotificationService.liveUpdateTrigger.removeListener(_onLiveNotificationReceived);
    super.dispose();
  }

  void _onLiveNotificationReceived() {
    if (mounted) {
      _loadNotifications(isSilent: true);
    }
  }

  Future<void> _loadNotifications({bool isSilent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
      return;
    }

    if (!isSilent) {
      setState(() {
        _isGuest = false;
        _isLoading = true;
      });
    }

    final data = await _service.fetchNotifications(category: _selectedCategory);
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    if (mounted) {
      setState(() {
        for (var n in _notifications) {
          n.isRead = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          backgroundColor: darkSlate,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Notifications?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate)),
        content: Text('Are you sure you want to delete all notifications? This cannot be undone.', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear All', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearAll();
      if (mounted) {
        setState(() {
          _notifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications cleared', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
            backgroundColor: darkSlate,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(UserNotificationModel notif) async {
    if (!notif.isRead) {
      setState(() => notif.isRead = true);
      await _service.markAsRead(notif.id);
    }

    if (!mounted) return;

    // Clean dialog without emojis or gradient
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderSubtle),
              ),
              child: Icon(notif.iconData, color: darkSlate, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif.title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: darkSlate),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.message,
              style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF334155), height: 1.45),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Text(
                    notif.category.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                  ),
                ),
                Text(
                  notif.timeAgo,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(color: darkSlate, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: subtleBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderSubtle),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                color: darkSlate,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread updates',
                style: GoogleFonts.poppins(
                  color: primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: darkSlate),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'mark_read') {
                  _markAllAsRead();
                } else if (val == 'clear_all') {
                  _clearAll();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 18, color: darkSlate),
                      const SizedBox(width: 10),
                      Text('Mark all as read', style: GoogleFonts.poppins(fontSize: 13, color: darkSlate)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red.shade600),
                      const SizedBox(width: 10),
                      Text('Clear all', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade600)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isGuest
          ? _buildGuestState()
          : Column(
              children: [
                // Filter Chips Row - Clean & Minimal
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() => _selectedCategory = cat['id']!);
                              _loadNotifications();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? darkSlate : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? darkSlate : borderSubtle,
                                ),
                              ),
                              child: Text(
                                cat['label']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: borderSubtle),

                // Notifications List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2.5))
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: primaryGreen,
                              onRefresh: _loadNotifications,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: _notifications.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (ctx, index) {
                                  final notif = _notifications[index];
                                  return _buildNotificationCard(notif);
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(UserNotificationModel notif) {
    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (dir) async {
        final removed = notif;
        final removedIndex = _notifications.indexOf(notif);
        setState(() => _notifications.removeAt(removedIndex));
        await _service.deleteNotification(removed.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification dismissed', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
              backgroundColor: darkSlate,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'UNDO',
                textColor: const Color(0xFF86EFAC),
                onPressed: () {
                  setState(() => _notifications.insert(removedIndex, removed));
                },
              ),
            ),
          );
        }
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notif.isRead ? borderSubtle : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Flat Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderSubtle),
                ),
                child: Icon(notif.iconData, color: darkSlate, size: 19),
              ),
              const SizedBox(width: 12),

              // Title, Message, Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.poppins(
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 13.5,
                              color: darkSlate,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: borderSubtle),
                          ),
                          child: Text(
                            notif.category.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Text(
                          notif.timeAgo,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderSubtle),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 46,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All updates regarding inquiries, scheme applications, bids, and orders will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 16, color: darkSlate),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: darkSlate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderSubtle),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Sign In Required',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log into your Dhartti account to view updates on your applications, inquiries, and bids.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ).then((_) => _loadNotifications());
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sign In to Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ).then((_) => _loadNotifications());
              },
              child: Text(
                'Don’t have an account? Register',
                style: GoogleFonts.poppins(
                  color: darkSlate,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
