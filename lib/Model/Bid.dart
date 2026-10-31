class Bid {
  final int id;
  final int userId;
  final int projectId;
  final String? bidPrice;
  final String? bidDescription;
  String? username;
  final String status;
  final String? ownerReply;

  Bid({
    required this.id,
    required this.userId,
    required this.projectId,
    this.bidPrice,
    this.bidDescription,
    this.username,
    this.status = 'Pending',
    this.ownerReply,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : (json['user_id'] is int
              ? json['user_id']
              : int.tryParse((json['userId'] ?? json['user_id'])?.toString() ?? '0') ?? 0),
      projectId: json['project_id'] is int
          ? json['project_id']
          : (json['projectId'] is int
              ? json['projectId']
              : int.tryParse((json['project_id'] ?? json['projectId'])?.toString() ?? '0') ?? 0),
      bidPrice: json['bid_price']?.toString() ?? json['bidPrice']?.toString(),
      bidDescription: json['bid_description']?.toString() ?? json['bidDescription']?.toString(),
      username: json['username']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      ownerReply: json['owner_reply']?.toString() ?? json['ownerReply']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'project_id': projectId,
      'bid_price': bidPrice,
      'bid_description': bidDescription,
      'username': username,
      'status': status,
      'owner_reply': ownerReply,
    };
  }
}
