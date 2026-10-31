class PropertyInquiry {
  final int? propertyId;
  final String? message;
  final String? inquiryType;

  PropertyInquiry({
    required this.propertyId,
    required this.message,
    required this.inquiryType,
  });

  Map<String, dynamic> toJson() {
    return {
      'property_id': propertyId,
      'message': message,
      'inquiry_type': inquiryType,
    };
  }
}
