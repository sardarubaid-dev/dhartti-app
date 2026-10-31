class Property {
  int? id;
  String? purpose; // Sell, Rent
  String? propertyType; // Home, Plots, Commercial
  String? subPropertyType; // House, Flat, Residential Plot, etc.
  String? city;
  String? video_url; // Remove the videoUrl field and keep only this one
  double? latitude;
  double? longitude;
  String? plotNumber;
  double? areaSize;
  String? areaUnit; // Square Feet, Square Meters, etc.
  double? price;
  String? currency; // PKR, USD, etc.
  bool? installmentAvailable;
  double? advanceAmount;
  int? noOfInstallments;
  double? monthlyInstallment;
  bool? readyForPossession;
  int? bedrooms;
  int? bathrooms;
  String? amenities; // JSON or text
  String? title;
  String? description;
  String? videoUrl; // Video URL field as string
  String? imagePath;
  String? email;
  List<String>? mobileNumbers; // List of strings for mobile numbers
  String? landline;
  bool? isPopular;
  bool? isRecommended;
  bool? isFeatured;
  bool? isHot;
  bool? isSuperHot;
  bool? isActive;
  int? userId;
  String? whatsappNumber;
  String? imagePath2;
  String? imagePath3;
  String? imagePath4;
  String? imagePath5;
  String? flooring; // Dropdown
  String? electricityBackup; // Dropdown
  String? view;
  String? otherMainFeatures;
  int? builtInYear;
  int? parkingSpaces;
  int? floors;
  bool? doubleGlazedWindows;
  bool? centralAirConditioning;
  bool? centralHeating;

  // Rooms
  String? otherRooms;
  String? servantQuarters;
  int? kitchens;
  int? storeRooms;
  bool? drawingRoom;
  bool? diningRoom;
  bool? studyRoom;
  bool? prayerRoom;
  bool? powderRoom;
  bool? gym;
  bool? steamRoom;
  bool? loungeOrSittingRoom;
  bool? laundryRoom;

  // Business and Communication
  String? otherBusinessCommunicationFacilities;
  bool? broadbandInternetAccess;
  bool? satelliteOrCableTvReady;
  bool? intercom;

  // Community Features
  String? otherCommunityFacilities;
  bool? communityLawnOrGarden;
  bool? communitySwimmingPool;
  bool? communityGym;
  bool? firstAidOrMedicalCentre;
  bool? dayCareCentre;
  bool? kidsPlayArea;
  bool? barbequeArea;
  bool? mosque;
  bool? communityCentre;

  // Healthcare Recreational
  String? otherHealthcareRecreationFacilities;
  bool? lawnOrGarden;
  bool? swimmingPool;
  bool? sauna;
  bool? jacuzzi;

  // Nearby Locations and Other Facilities
  String? nearbySchools;
  String? nearbyHospitals;
  String? nearbyShoppingMalls;
  String? nearbyRestaurants;
  double? distanceFromAirportKms;
  String? nearbyPublicTransportService;
  String? otherNearbyPlaces;

  // Other Facilities
  String? otherFacilities;
  bool? maintenanceStaff;
  bool? securityStaff;
  bool? facilitiesForDisabled;

  Property({
    this.id,
    this.purpose,
    this.propertyType,
    this.subPropertyType,
    this.city,
    this.latitude,
    this.longitude,
    this.plotNumber,
    this.areaSize,
    this.video_url,
    this.areaUnit,
    this.price,
    this.currency,
    this.installmentAvailable,
    this.advanceAmount,
    this.noOfInstallments,
    this.monthlyInstallment,
    this.readyForPossession,
    this.bedrooms,
    this.bathrooms,
    this.amenities,
    this.title,
    this.description,
    this.videoUrl,
    this.imagePath,
    this.email,
    this.mobileNumbers,
    this.landline,
    this.isPopular,
    this.isRecommended,
    this.isFeatured,
    this.isHot,
    this.isSuperHot,
    this.isActive,
    this.userId,
    this.whatsappNumber,
    this.imagePath2,
    this.imagePath3,
    this.imagePath4,
    this.imagePath5,
    this.flooring,
    this.electricityBackup,
    this.view,
    this.otherMainFeatures,
    this.builtInYear,
    this.parkingSpaces,
    this.floors,
    this.doubleGlazedWindows,
    this.centralAirConditioning,
    this.centralHeating,
    this.otherRooms,
    this.servantQuarters,
    this.kitchens,
    this.storeRooms,
    this.drawingRoom,
    this.diningRoom,
    this.studyRoom,
    this.prayerRoom,
    this.powderRoom,
    this.gym,
    this.steamRoom,
    this.loungeOrSittingRoom,
    this.laundryRoom,
    this.otherBusinessCommunicationFacilities,
    this.broadbandInternetAccess,
    this.satelliteOrCableTvReady,
    this.intercom,
    this.otherCommunityFacilities,
    this.communityLawnOrGarden,
    this.communitySwimmingPool,
    this.communityGym,
    this.firstAidOrMedicalCentre,
    this.dayCareCentre,
    this.kidsPlayArea,
    this.barbequeArea,
    this.mosque,
    this.communityCentre,
    this.otherHealthcareRecreationFacilities,
    this.lawnOrGarden,
    this.swimmingPool,
    this.sauna,
    this.jacuzzi,
    this.nearbySchools,
    this.nearbyHospitals,
    this.nearbyShoppingMalls,
    this.nearbyRestaurants,
    this.distanceFromAirportKms,
    this.nearbyPublicTransportService,
    this.otherNearbyPlaces,
    this.otherFacilities,
    this.maintenanceStaff,
    this.securityStaff,
    this.facilitiesForDisabled,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      purpose: json['purpose'],
      propertyType: json['property_type'],
      subPropertyType: json['sub_property_type'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      plotNumber: json['plot_number'],
      areaSize: json['area_size'],
      areaUnit: json['area_unit'],
      price: json['price'],
      video_url:json['video_url'],
      currency: json['currency'],
      installmentAvailable: json['installment_available'],
      readyForPossession: json['ready_for_possession'],
      advanceAmount: json['advance_amount'],
      noOfInstallments: json['no_of_installments'],
      monthlyInstallment: json['monthly_installment'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      amenities: json['amenities'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url'],
      imagePath: json['image_path'],
      email: json['email'],
      mobileNumbers: json['mobile_numbers'] != null ? List<String>.from(json['mobile_numbers']) : [],
      landline: json['landline'],
      isPopular: json['isPopular'],
      isRecommended: json['isRecommended'],
      isFeatured: json['isFeatured'],
      isHot: json['is_hot'],
      isSuperHot: json['is_super_hot'],
      isActive: json['is_active'],
      userId: json['userId'],
      whatsappNumber: json['whatsappnumber'],
      imagePath2: json['image_pat2'],
      imagePath3: json['image_path3'],
      imagePath4: json['image_path4'],
      imagePath5: json['image_path5'],
      flooring: json['flooring'],
      electricityBackup: json['electricity_backup'],
      view: json['view'],
      otherMainFeatures: json['other_main_features'],
      builtInYear: json['built_in_year'],
      parkingSpaces: json['parking_spaces'],
      floors: json['floors'],
      doubleGlazedWindows: json['double_glazed_windows'],
      centralAirConditioning: json['central_air_conditioning'],
      centralHeating: json['central_heating'],
      otherRooms: json['other_rooms'],
      servantQuarters: json['servant_quarters'],
      kitchens: json['kitchens'],
      storeRooms: json['store_rooms'],
      drawingRoom: json['drawing_room'],
      diningRoom: json['dining_room'],
      studyRoom: json['study_room'],
      prayerRoom: json['prayer_room'],
      powderRoom: json['powder_room'],
      gym: json['gym'],
      steamRoom: json['steam_room'],
      loungeOrSittingRoom: json['lounge_or_sitting_room'],
      laundryRoom: json['laundry_room'],
      otherBusinessCommunicationFacilities: json['other_business_communication_facilities'],
      broadbandInternetAccess: json['broadband_internet_access'],
      satelliteOrCableTvReady: json['satellite_or_cable_tv_ready'],
      intercom: json['intercom'],
      otherCommunityFacilities: json['other_community_facilities'],
      communityLawnOrGarden: json['community_lawn_or_garden'],
      communitySwimmingPool: json['community_swimming_pool'],
      communityGym: json['community_gym'],
      firstAidOrMedicalCentre: json['first_aid_or_medical_centre'],
      dayCareCentre: json['day_care_centre'],
      kidsPlayArea: json['kids_play_area'],
      barbequeArea: json['barbeque_area'],
      mosque: json['mosque'],
      communityCentre: json['community_centre'],
      otherHealthcareRecreationFacilities: json['other_healthcare_recreation_facilities'],
      lawnOrGarden: json['lawn_or_garden'],
      swimmingPool: json['swimming_pool'],
      sauna: json['sauna'],
      jacuzzi: json['jacuzzi'],
      nearbySchools: json['nearby_schools'],
      nearbyHospitals: json['nearby_hospitals'],
      nearbyShoppingMalls: json['nearby_shopping_malls'],
      nearbyRestaurants: json['nearby_restaurants'],
      distanceFromAirportKms: json['distance_from_airport_kms'],
      nearbyPublicTransportService: json['nearby_public_transport_service'],
      otherNearbyPlaces: json['other_nearby_places'],
      otherFacilities: json['other_facilities'],
      maintenanceStaff: json['maintenance_staff'],
      securityStaff: json['security_staff'],
      facilitiesForDisabled: json['facilities_for_disabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'property_type': propertyType,
      'sub_property_type': subPropertyType,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'plot_number': plotNumber,
      'area_size': areaSize,
      'area_unit': areaUnit,
      'price': price,
      'currency': currency,
      'installment_available': installmentAvailable ?? false,
      'ready_for_possession': readyForPossession ?? false,
      'advance_amount': advanceAmount,
      'no_of_installments': noOfInstallments,
      'monthly_installment': monthlyInstallment,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'title': title,
      'description': description,
      'video_url': videoUrl ?? video_url,
      'image_path': imagePath,
      'email': email,
      'mobile_numbers': mobileNumbers,
      'landline': landline,
      'isPopular': isPopular,
      'isRecommended': isRecommended??false,
      'isFeatured': isFeatured,
      'is_hot': isHot,
      'is_super_hot': isSuperHot,
      'is_active': isActive,
      'userId': userId,
      'whatsappnumber': whatsappNumber,
      'image_pat2': imagePath2,
      'image_path3': imagePath3,
      'image_path4': imagePath4,
      'image_path5': imagePath5,
      'flooring': flooring,
      'electricity_backup': electricityBackup,
      'view': view,
      'other_main_features': otherMainFeatures,
      'built_in_year': builtInYear,
      'parking_spaces': parkingSpaces,
      'floors': floors,
      'double_glazed_windows': doubleGlazedWindows,
      'central_air_conditioning': centralAirConditioning,
      'central_heating': centralHeating,
      'other_rooms': otherRooms,
      'servant_quarters': servantQuarters,
      'kitchens': kitchens,
      'store_rooms': storeRooms,
      'drawing_room': drawingRoom,
      'dining_room': diningRoom,
      'study_room': studyRoom,
      'prayer_room': prayerRoom,
      'powder_room': powderRoom,
      'gym': gym,
      'steam_room': steamRoom,
      'lounge_or_sitting_room': loungeOrSittingRoom,
      'laundry_room': laundryRoom,
      'other_business_communication_facilities': otherBusinessCommunicationFacilities,
      'broadband_internet_access': broadbandInternetAccess,
      'satellite_or_cable_tv_ready': satelliteOrCableTvReady,
      'intercom': intercom,
      'other_community_facilities': otherCommunityFacilities,
      'community_lawn_or_garden': communityLawnOrGarden,
      'community_swimming_pool': communitySwimmingPool,
      'community_gym': communityGym,
      'first_aid_or_medical_centre': firstAidOrMedicalCentre,
      'day_care_centre': dayCareCentre,
      'kids_play_area': kidsPlayArea,
      'barbeque_area': barbequeArea,
      'mosque': mosque,
      'community_centre': communityCentre,
      'other_healthcare_recreation_facilities': otherHealthcareRecreationFacilities,
      'lawn_or_garden': lawnOrGarden,
      'swimming_pool': swimmingPool,
      'sauna': sauna,
      'jacuzzi': jacuzzi,
      'nearby_schools': nearbySchools,
      'nearby_hospitals': nearbyHospitals,
      'nearby_shopping_malls': nearbyShoppingMalls,
      'nearby_restaurants': nearbyRestaurants,
      'distance_from_airport_kms': distanceFromAirportKms,
      'nearby_public_transport_service': nearbyPublicTransportService,
      'other_nearby_places': otherNearbyPlaces,
      'other_facilities': otherFacilities,
      'maintenance_staff': maintenanceStaff,
      'security_staff': securityStaff,
      'facilities_for_disabled': facilitiesForDisabled,
    };
  }
}
