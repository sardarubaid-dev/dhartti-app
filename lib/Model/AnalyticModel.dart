class Property {
  final int id;
  final String title;
  final String description;
  final String whatsappNumber;
  final String phoneNumber;
  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.whatsappNumber,
    required this.phoneNumber,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      whatsappNumber: json['whatsapp_number'],
      phoneNumber: json['phone_number'],
    );
  }
}
