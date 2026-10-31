class ApplyLoan {
  final int id;
  final int userId;
  final int loanId;
  final String name;
  final String email;
  final String number;
  final String cnic;
  final String city;
  final double salary;
  final String status;
  final DateTime? createdAt;

  ApplyLoan({
    required this.id,
    required this.userId,
    required this.loanId,
    required this.name,
    required this.email,
    required this.number,
    required this.cnic,
    required this.city,
    required this.salary,
    this.status = 'pending',
    this.createdAt,
  });

  factory ApplyLoan.fromJson(Map<String, dynamic> json) {
    return ApplyLoan(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? json['user_id']?.toString() ?? '0') ?? 0,
      loanId: json['loan_id'] is int
          ? json['loan_id']
          : int.tryParse(json['loan_id']?.toString() ?? json['Loan_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      cnic: json['cnic']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      salary: json['salary'] is num
          ? (json['salary'] as num).toDouble()
          : double.tryParse(json['salary']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loan_id': loanId,
      'user_id': userId,
      'userId': userId,
      'name': name,
      'email': email,
      'number': number,
      'cnic': cnic,
      'city': city,
      'salary': salary,
    };
  }
}
