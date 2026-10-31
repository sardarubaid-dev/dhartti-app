import 'package:dhartti/Model/user_model.dart';

class JoinVentureBid {
  final int id;
  final int ventureId;
  final int userId;
  final String? amount;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final int bidsCount;
  final String status;
  final String? ownerReply;
  final bool isMine;
  final String bidderName;
  final String? bidderPhone;
  final String? bidderEmail;

  JoinVentureBid({
    required this.id,
    required this.ventureId,
    required this.userId,
    required this.amount,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    required this.bidsCount,
    this.status = 'Pending',
    this.ownerReply,
    this.isMine = false,
    this.bidderName = 'Partner',
    this.bidderPhone,
    this.bidderEmail,
  });

  factory JoinVentureBid.fromJson(Map<String, dynamic> json) {
    String name = json['username']?.toString() ?? '';
    if (name.isEmpty && json['user'] != null && json['user'] is Map) {
      name = json['user']['name']?.toString() ?? '';
    }
    if (name.isEmpty) name = 'Partner #${json['id'] ?? ''}';

    String? phone = json['user_phone']?.toString();
    if (phone == null && json['user'] != null && json['user'] is Map) {
      phone = json['user']['contact_number']?.toString() ?? json['user']['phone']?.toString();
    }

    String? email = json['user_email']?.toString();
    if (email == null && json['user'] != null && json['user'] is Map) {
      email = json['user']['email']?.toString();
    }

    return JoinVentureBid(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ventureId: json['venture_id'] ?? json['ventureId'] ?? 0,
      userId: json['user_id'] ?? json['userId'] ?? 0,
      message: json['message']?.toString(),
      amount: json['amount']?.toString(),
      createdAt: json['created_at_iso'] != null
          ? DateTime.tryParse(json['created_at_iso'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      user: json['user'] != null && json['user'] is Map ? User.fromJson(json['user']) : null,
      bidsCount: json['bids_venture_count'] ?? 0,
      status: json['status']?.toString() ?? 'Pending',
      ownerReply: json['owner_reply']?.toString(),
      isMine: json['is_mine'] == true,
      bidderName: name,
      bidderPhone: phone,
      bidderEmail: email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'venture_id': ventureId,
      'amount': amount,
      'message': message,
    };
  }
}
