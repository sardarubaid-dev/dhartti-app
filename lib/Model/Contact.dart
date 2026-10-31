class Contact {
  final int? userId;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? subject;
  final String message;

  Contact({
    required this.userId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.subject,
    required this.message,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      userId: json['userId'],
      name: json['Name'],
      email: json['Email'],
      phoneNumber: json['Phone_number'],
      subject: json['Subject'],
      message: json['Message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'Name': name,
      'Email': email,
      'Phone_number': phoneNumber,
      'Subject': subject,
      'Message': message,
    };
  }
}
