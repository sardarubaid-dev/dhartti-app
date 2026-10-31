import 'package:dhartti/service/blog_service.dart';

class Blog {
  final int? id;
  final int userId;
  final String blogHeading1;
  final String blogHeading2;
  final String blogHeading3;
  final String blogTag;
  final String blogDescription1;
  final String blogDescription2;
  final String blogDescription3;
  final String blogDescription4;
  final String blogDescription5;
  final String blogQuote;
  final String blogQuoteByPerson;
  final String? blogImage1;
  final String? blogImage2;
  final String? blogImage3;
  final String? blogImage4;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Blog({
    this.id,
    required this.userId,
    required this.blogHeading1,
    required this.blogHeading2,
    required this.blogHeading3,
    required this.blogTag,
    required this.blogDescription1,
    required this.blogDescription2,
    required this.blogDescription3,
    required this.blogDescription4,
    required this.blogDescription5,
    required this.blogQuote,
    required this.blogQuoteByPerson,
    this.blogImage1,
    this.blogImage2,
    this.blogImage3,
    this.blogImage4,
    this.createdAt,
    this.updatedAt,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId'] is int
          ? json['userId']
          : (int.tryParse(json['userId']?.toString() ?? '1') ?? 1),
      blogHeading1: json['Blog_heading_1']?.toString() ?? '',
      blogHeading2: json['Blog_heading_2']?.toString() ?? '',
      blogHeading3: json['Blog_heading_3']?.toString() ?? '',
      blogTag: json['Blog_tag']?.toString() ?? '#RealEstate',
      blogDescription1: json['Blog_description_1']?.toString() ?? '',
      blogDescription2: json['Blog_description_2']?.toString() ?? '',
      blogDescription3: json['Blog_description_3']?.toString() ?? '',
      blogDescription4: json['Blog_description_4']?.toString() ?? '',
      blogDescription5: json['Blog_description_5']?.toString() ?? '',
      blogQuote: json['Blog_quote']?.toString() ?? '',
      blogQuoteByPerson: json['Blog_quote_by_person']?.toString() ?? '',
      blogImage1: json['Blog_image_1'] != null && json['Blog_image_1'].toString().trim().isNotEmpty
          ? BlogService.formatImageUrl(json['Blog_image_1'].toString())
          : null,
      blogImage2: json['Blog_image_2'] != null && json['Blog_image_2'].toString().trim().isNotEmpty
          ? BlogService.formatImageUrl(json['Blog_image_2'].toString())
          : null,
      blogImage3: json['Blog_image_3'] != null && json['Blog_image_3'].toString().trim().isNotEmpty
          ? BlogService.formatImageUrl(json['Blog_image_3'].toString())
          : null,
      blogImage4: json['Blog_image_4'] != null && json['Blog_image_4'].toString().trim().isNotEmpty
          ? BlogService.formatImageUrl(json['Blog_image_4'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'Blog_heading_1': blogHeading1,
      'Blog_heading_2': blogHeading2,
      'Blog_heading_3': blogHeading3,
      'Blog_tag': blogTag,
      'Blog_description_1': blogDescription1,
      'Blog_description_2': blogDescription2,
      'Blog_description_3': blogDescription3,
      'Blog_description_4': blogDescription4,
      'Blog_description_5': blogDescription5,
      'Blog_quote': blogQuote,
      'Blog_quote_by_person': blogQuoteByPerson,
      'Blog_image_1': blogImage1,
      'Blog_image_2': blogImage2,
      'Blog_image_3': blogImage3,
      'Blog_image_4': blogImage4,
    };
  }

  // List of all non-empty images
  List<String> get allImages {
    final list = <String>[];
    if (blogImage1 != null && blogImage1!.trim().isNotEmpty) list.add(BlogService.formatImageUrl(blogImage1));
    if (blogImage2 != null && blogImage2!.trim().isNotEmpty) list.add(BlogService.formatImageUrl(blogImage2));
    if (blogImage3 != null && blogImage3!.trim().isNotEmpty) list.add(BlogService.formatImageUrl(blogImage3));
    if (blogImage4 != null && blogImage4!.trim().isNotEmpty) list.add(BlogService.formatImageUrl(blogImage4));
    return list;
  }

  // Estimated read time in minutes
  int get readTimeMinutes {
    final fullText = '$blogDescription1 $blogDescription2 $blogDescription3 $blogDescription4 $blogDescription5';
    final wordCount = fullText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final minutes = (wordCount / 180).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  // List of hashtags parsed
  List<String> get tagsList {
    if (blogTag.trim().isEmpty) return ['#RealEstate'];
    return blogTag
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();
  }
}
