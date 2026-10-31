class ConstructionCostModel {
  final int? id;
  final String city;
  final int userId;
  final double greyStructureMaterial;
  final double finishingMaterial;
  final double labourWithMaterial;
  final double labourWithoutMaterial;
  final double pricePerSqft;

  ConstructionCostModel({
    this.id,
    required this.city,
    required this.userId,
    required this.greyStructureMaterial,
    required this.finishingMaterial,
    required this.labourWithMaterial,
    required this.labourWithoutMaterial,
    required this.pricePerSqft,
  });

  factory ConstructionCostModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse doubles
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Explicitly cast each field
    return ConstructionCostModel(
      id: json['id'] as int?,
      city: json['city'] as String,
      userId: json['userId'] as int,
      greyStructureMaterial: parseDouble(json['grey_structure_material']),
      finishingMaterial: parseDouble(json['finishing_material']),
      labourWithMaterial: parseDouble(json['labour_with_material']),
      labourWithoutMaterial: parseDouble(json['labour_without_material']),
      pricePerSqft: parseDouble(json['price_per_sqft']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'city': city,
      'userId': userId,
      'grey_structure_material': greyStructureMaterial,
      'finishing_material': finishingMaterial,
      'labour_with_material': labourWithMaterial,
      'labour_without_material': labourWithoutMaterial,
      'price_per_sqft': pricePerSqft,
    };
  }
}
