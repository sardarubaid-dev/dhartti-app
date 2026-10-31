import 'package:dhartti/Model/join_venture_bid_model.dart';
import 'package:dhartti/Model/user_model.dart';

class JoinVenture {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String industry;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final List<JoinVentureBid>? bids;
  final int bidsCount;

  JoinVenture({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.industry,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.bids,
    required this.bidsCount,
  });

  factory JoinVenture.fromJson(Map<String, dynamic> json) {
    int parsedCount = 0;
    final dynamic rawCount = json['bids_venture_count'] ?? json['bids_count'] ?? json['bidsCount'];
    if (rawCount != null) {
      if (rawCount is int) {
        parsedCount = rawCount;
      } else if (rawCount is num) {
        parsedCount = rawCount.toInt();
      } else {
        parsedCount = int.tryParse(rawCount.toString()) ?? 0;
      }
    } else if (json['bids_venture'] is List) {
      parsedCount = (json['bids_venture'] as List).length;
    } else if (json['bids'] is List) {
      parsedCount = (json['bids'] as List).length;
    }

    return JoinVenture(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: json['user_id'] ?? json['userId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      industry: json['industry'] ?? '',
      location: json['location'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      bids: json['bids_venture'] != null
          ? (json['bids_venture'] as List).map((bid) => JoinVentureBid.fromJson(bid)).toList()
          : null,
      bidsCount: parsedCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'industry': industry,
      'location': location,
      'bids_venture_count': bidsCount,
    };
  }
}
