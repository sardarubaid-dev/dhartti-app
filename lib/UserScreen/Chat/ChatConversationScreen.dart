import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dhartti/service/chat_service.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';

class ChatConversationScreen extends StatefulWidget {
  final int roomId;
  final String otherUserName;
  final String otherUserRole;
  final String? contextTitle;
  final int? propertyId;
  final dynamic propertyPrice;
  final String? propertyCity;

  const ChatConversationScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    this.otherUserRole = 'Seller',
    this.contextTitle,
    this.propertyId,
    this.propertyPrice,
    this.propertyCity,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  static const Color dharttiGreen = Color(0xFF108224);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color chatBg = Color(0xFFF8FAFC);

  // Quick suggestion chips for real estate inquiries
  final List<String> _quickSuggestions = [
    'Is this property still available?',
    'What is the final demand/price?',
    'Can I schedule a site visit this week?',
    'Please share complete location & photos.',
    'Are installment plans or loans available?',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _restoreDraft();

    // Live auto-poll every 3 seconds for real-time incoming messages
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollNewMessages();
    });

    // Save draft as user types
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _saveDraft();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _chatService.saveDraft(widget.roomId, _messageController.text);
  }

  Future<void> _restoreDraft() async {
    final draft = await _chatService.getDraft(widget.roomId);
    if (draft.isNotEmpty && mounted) {
      _messageController.text = draft;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    }
  }

  Future<void> _saveDraft() async {
    await _chatService.saveDraft(widget.roomId, _messageController.text);
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _chatService.fetchRoomMessages(widget.roomId);
      final List msgs = res['messages'] ?? [];
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(msgs.map((m) => Map<String, dynamic>.from(m)));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pollNewMessages() async {
    if (_isSending) return;
    try {
      final res = await _chatService.fetchRoomMessages(widget.roomId);
      final List msgs = res['messages'] ?? [];
      if (mounted && msgs.length != _messages.length) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(msgs.map((m) => Map<String, dynamic>.from(m)));
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Optimistic message update
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimisticMsg = {
      'id': tempId,
      'is_mine': true,
      'text': text,
      'time': 'Just now',
      'is_read': false,
    };

    setState(() {
      _messages.add(optimisticMsg);
    });
    if (quickText == null) _messageController.clear();
    await _chatService.clearDraft(widget.roomId);
    _scrollToBottom();

    try {
      final res = await _chatService.sendMessage(
        roomId: widget.roomId,
        message: text,
      );

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx] = res;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deliver message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        if (quickText == null) _messageController.text = text;
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatPrice(dynamic rawPrice) {
    if (rawPrice == null) return '';
    final double? price = double.tryParse(rawPrice.toString().replaceAll(',', '').replaceAll('PKR', '').trim());
    if (price == null || price <= 0) return '';
    if (price >= 10000000) {
      final crore = price / 10000000;
      return 'PKR ${crore.toStringAsFixed(crore.truncateToDouble() == crore ? 0 : 2)} Crore';
    } else if (price >= 100000) {
      final lac = price / 100000;
      return 'PKR ${lac.toStringAsFixed(lac.truncateToDouble() == lac ? 0 : 2)} Lakh';
    }
    return 'PKR ${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPropertyContext = widget.propertyId != null && widget.propertyId! > 0;
    final otherInitial = widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar with Online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: dharttiGreen.withValues(alpha: 0.12),
                  child: Text(
                    otherInitial,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: dharttiGreen,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Name & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified ${widget.otherUserRole} • Active',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: dharttiGreen, size: 21),
            tooltip: 'Refresh',
            onPressed: _loadMessages,
          ),
          if (hasPropertyContext)
            IconButton(
              icon: const Icon(Icons.home_work_outlined, color: textDark, size: 21),
              tooltip: 'View Property Listing',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PropertyDetailPage(propertyId: widget.propertyId!)),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Deal Context Header Banner
              if (widget.contextTitle != null && widget.contextTitle!.isNotEmpty)
                _buildDealBanner(hasPropertyContext),

              // Message Bubbles List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: dharttiGreen))
                    : _messages.isEmpty
                        ? _buildEmptyConversationState()
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMine = msg['is_mine'] == true;
                              return _buildMessageBubble(msg, isMine);
                            },
                          ),
              ),

              // Quick Suggestions Carousel
              _buildSuggestionsBar(),

              // Input Bar with Double-Click Protection
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealBanner(bool hasPropertyContext) {
    return InkWell(
      onTap: hasPropertyContext
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailPage(propertyId: widget.propertyId!),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work_rounded, color: dharttiGreen, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contextTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: textDark,
                    ),
                  ),
                  if (widget.propertyPrice != null || widget.propertyCity != null)
                    Text(
                      '${_formatPrice(widget.propertyPrice)} ${widget.propertyCity != null ? '• ${widget.propertyCity}' : ''}'.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dharttiGreen,
                      ),
                    ),
                ],
              ),
            ),
            if (hasPropertyContext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dharttiGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Listing',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Colors.white),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: dharttiGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.forum_outlined, size: 40, color: dharttiGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Direct Property Discussion',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Negotiate prices, request visits or ask about financing directly with ${widget.otherUserName}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: _quickSuggestions.map((text) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _sendMessage(text),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 13,
              backgroundColor: dharttiGreen.withValues(alpha: 0.12),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.bold, color: dharttiGreen),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        colors: [Color(0xFF108224), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMine ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                border: isMine ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: isMine ? dharttiGreen.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: isMine ? Colors.white : textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg['time'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isMine ? Colors.white.withValues(alpha: 0.75) : textMuted,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 13,
                          color: msg['is_read'] == true ? const Color(0xFF93C5FD) : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Type your message or offer...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button with animated state
            InkWell(
              onTap: _isSending ? null : () => _sendMessage(),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF108224), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dharttiGreen.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
