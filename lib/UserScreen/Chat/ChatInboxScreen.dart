import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/service/chat_service.dart';
import 'package:dhartti/UserScreen/Chat/ChatConversationScreen.dart';
import 'package:dhartti/Auth_Screens/login.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/BottomNavbar.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  bool _isGuest = false;
  Timer? _refreshTimer;
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Unread, Sellers, Contractors
  final TextEditingController _searchController = TextEditingController();

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _checkGuestAndLoad();

    // Auto-refresh rooms list every 5 seconds for incoming conversations
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isGuest && mounted) _loadRooms(silent: true);
    });
  }

  Future<void> _checkGuestAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawUserId = prefs.get('userId') ?? prefs.get('user_id');
    final token = prefs.getString('token');

    if (rawUserId == null || token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _isLoading = false;
        });
      }
    } else {
      _loadRooms();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final list = await _chatService.fetchChatRooms();
      if (mounted) {
        setState(() {
          _rooms = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRooms {
    return _rooms.where((room) {
      final otherName = (room['other_user_name'] ?? '').toString().toLowerCase();
      final otherRole = (room['other_user_role'] ?? '').toString().toLowerCase();
      final contextTitle = (room['context'] ?? '').toString().toLowerCase();
      final lastMsg = (room['last_message'] ?? '').toString().toLowerCase();
      final unread = room['unread'] ?? 0;

      // Filter category
      if (_selectedFilter == 'Unread' && unread == 0) return false;
      if (_selectedFilter == 'Sellers' && !otherRole.contains('seller')) return false;
      if (_selectedFilter == 'Contractors' && !otherRole.contains('contractor')) return false;

      // Search query
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      return otherName.contains(q) ||
          otherRole.contains(q) ||
          contextTitle.contains(q) ||
          lastMsg.contains(q);
    }).toList();
  }

  int get _totalUnreadCount {
    int total = 0;
    for (var r in _rooms) {
      final unread = r['unread'];
      if (unread is int) total += unread;
      if (unread is String) total += int.tryParse(unread) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Messages & Chats',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: textDark,
                  ),
                ),
                if (_totalUnreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: dharttiGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_totalUnreadCount new',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              'Direct inquiries with property sellers',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: dharttiGreen, size: 21),
            onPressed: () => _loadRooms(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
          : _isGuest
              ? _buildGuestView()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      children: [
                        // Search & Filter Category Bar
                        _buildSearchAndFilters(),

                        // Conversation List
                        Expanded(
                          child: _filteredRooms.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: dharttiGreen,
                                  onRefresh: () => _loadRooms(),
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                                    itemCount: _filteredRooms.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final room = _filteredRooms[index];
                                      return _buildRoomTile(room);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search Input
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.poppins(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search chats, sellers, or properties...',
                hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: dharttiGreen, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'Unread', 'Sellers', 'Contractors'].map((tab) {
                final isSelected = _selectedFilter == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tab),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : textDark,
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = tab),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: dharttiGreen,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? dharttiGreen : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 54, color: dharttiGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign In to View Messages',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to access your ongoing discussions, inquiries, and offers with property sellers and contractors.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
              label: Text(
                'Sign In Now',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dharttiGreen,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty || _selectedFilter != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isSearching ? Icons.search_off_rounded : Icons.forum_outlined,
                  size: 44,
                  color: dharttiGreen,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'No Matching Chats Found' : 'No Messages Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search query or switching the category filter.'
                  : 'Whenever you tap "Message Seller" or inquire on any property, your live conversations will appear right here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: textMuted, height: 1.5),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen(initialIndex: 1)),
                  );
                },
                icon: const Icon(Icons.explore_outlined, color: Colors.white, size: 18),
                label: Text(
                  'Browse Properties & Inquire',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dharttiGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile(Map<String, dynamic> room) {
    final int roomId = room['id'];
    final String otherName = room['other_user_name'] ?? 'User';
    final String otherRole = room['other_user_role'] ?? 'Seller';
    final String contextTitle = room['context'] ?? 'Property Inquiry';
    final String lastMessage = room['last_message'] ?? 'No messages yet';
    final String lastTime = room['last_time'] ?? '';
    final int unread = room['unread'] ?? 0;
    final int? propertyId = room['property_id'];

    Color roleColor;
    Color roleBg;
    if (otherRole.toLowerCase().contains('contractor')) {
      roleColor = const Color(0xFF0F766E);
      roleBg = const Color(0xFFCCFBF1);
    } else if (otherRole.toLowerCase().contains('seller')) {
      roleColor = const Color(0xFFB45309);
      roleBg = const Color(0xFFFEF3C7);
    } else {
      roleColor = const Color(0xFF0369A1);
      roleBg = const Color(0xFFE0F2FE);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unread > 0 ? dharttiGreen.withValues(alpha: 0.35) : Colors.grey.shade200,
          width: unread > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: unread > 0
                ? dharttiGreen.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatConversationScreen(
                  roomId: roomId,
                  otherUserName: otherName,
                  otherUserRole: otherRole,
                  contextTitle: contextTitle,
                  propertyId: propertyId,
                ),
              ),
            ).then((_) => _loadRooms(silent: true));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: dharttiGreen.withValues(alpha: 0.12),
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: dharttiGreen,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name, Role, Property Context & Last Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Name + Role Badge + Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    otherName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    otherRole,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            lastTime,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: unread > 0 ? dharttiGreen : textMuted,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Property Inquired Context Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_outlined, size: 12, color: dharttiGreen),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                contextTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Last Message & Unread Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: unread > 0 ? textDark : textMuted,
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: dharttiGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: dharttiGreen.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                unread.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
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
      ),
    );
  }
}
