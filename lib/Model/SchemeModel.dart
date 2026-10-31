class Scheme {
  final int id;
  final int userId;
  final String? schemeName;
  final double? monthlyInstallment;
  final double? propertyValue;
  final double? downPayment;
  final double? loanAmount;
  final double? interestRate;
  final String? loanType;
  final bool employmentStatus;
  final int applicationsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Scheme({
    required this.id,
    required this.userId,
    this.schemeName,
    this.monthlyInstallment,
    this.propertyValue,
    this.downPayment,
    this.loanAmount,
    this.interestRate,
    this.loanType,
    this.employmentStatus = false,
    this.applicationsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId'] ?? json['user_id']),
      schemeName: json['scheme_name'] as String?,
      monthlyInstallment: _parseDouble(json['monthly_installment']),
      propertyValue: _parseDouble(json['property_value']),
      downPayment: _parseDouble(json['down_payment']),
      loanAmount: _parseDouble(json['loan_amount']),
      interestRate: _parseDouble(json['interest_rate']),
      loanType: json['loan_type'] as String?,
      employmentStatus: json['employment_status'] == 1 ||
          json['employment_status'] == true ||
          (json['employment_status'] is String &&
              json['employment_status'].toLowerCase() == 'true'),
      applicationsCount: _parseInt(json['applications_count'] ?? json['applicationsCount']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scheme_name': schemeName,
      'monthly_installment': monthlyInstallment,
      'property_value': propertyValue,
      'down_payment': downPayment,
      'loan_amount': loanAmount,
      'interest_rate': interestRate,
      'loan_type': loanType,
      'employment_status': employmentStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
