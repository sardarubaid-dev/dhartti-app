import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:dhartti/Model/property_model.dart';
import 'package:dhartti/service/property_Service.dart';
import 'package:dhartti/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Pakistani cities with their standard latitude and longitude coordinates
const Map<String, List<double>> kPakistanCitiesCoordinates = {
  'Islamabad': [33.6844, 73.0479],
  'Rawalpindi': [33.5651, 73.0169],
  'Lahore': [31.5204, 74.3587],
  'Karachi': [24.8607, 67.0011],
  'Faisalabad': [31.4504, 73.1350],
  'Multan': [30.1575, 71.5249],
  'Peshawar': [34.0151, 71.5249],
  'Quetta': [30.1798, 66.9750],
  'Gujranwala': [32.1877, 74.1945],
  'Sialkot': [32.4945, 74.5229],
  'Hyderabad': [25.3960, 68.3578],
  'Abbottabad': [34.1688, 73.2215],
  'Bahawalpur': [29.3544, 71.6911],
  'Sargodha': [32.0836, 72.6711],
  'Sukkur': [27.7052, 68.8574],
  'Larkana': [27.5589, 68.2120],
  'Sheikhupura': [31.7167, 73.9850],
  'Rahim Yar Khan': [28.4202, 70.3035],
  'Jhang': [31.2778, 72.3167],
  'Gujrat': [32.5742, 74.0754],
  'Mardan': [34.1989, 72.0450],
  'Kasur': [31.1167, 74.4500],
  'Dera Ghazi Khan': [30.0561, 70.6348],
  'Sahiwal': [30.6667, 73.1000],
  'Wah Cantonment': [33.7744, 72.7533],
  'Mirpur Khas': [25.5269, 69.0111],
  'Okara': [30.8081, 73.4458],
  'Mandi Bahauddin': [32.5870, 73.4912],
  'Jacobabad': [28.2835, 68.4388],
  'Jhelum': [32.9405, 73.7276],
  'Khanewal': [30.3017, 71.9321],
  'Muzaffargarh': [30.0754, 71.1921],
  'Murree': [33.9070, 73.3943],
  'Gwadar': [25.1216, 62.3254],
  'Swat': [35.2227, 72.4258],
  'Kohat': [33.5869, 71.4414],
  'Chiniot': [31.7200, 72.9789],
  'Hafizabad': [32.0717, 73.6878],
  'Muzaffarabad': [34.3700, 73.4711],
  'Mirpur AJK': [33.1478, 73.7519],
  'Taxila': [33.7463, 72.8397],
  'Nowshera': [34.0153, 71.9747],
};

// Sub-property types mapped dynamically to property type
const Map<String, List<String>> kPropertySubTypes = {
  'home': ['House', 'Flat', 'Upper Portion', 'Lower Portion', 'Farm House', 'Room', 'Penthouse'],
  'plots': ['Residential Plot', 'Commercial Plot', 'Agricultural Land', 'Industrial Land', 'Plot File', 'Plot Form'],
  'commercial': ['Office', 'Shop', 'Warehouse', 'Factory', 'Building', 'Other'],
};

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  const EditPropertyScreen({Key? key, required this.property}) : super(key: key);

  @override
  _EditPropertyScreenState createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Dropdown Form State
  late String _purpose;
  late String _propertyType;
  late String _subPropertyType;
  late String _city;
  late String _currency;
  late String _areaUnit;
  late String _flooring;
  late String _electricityBackup;
  late int _bedrooms;
  late int _bathrooms;

  // Auto coordinates
  late double _latitude;
  late double _longitude;

  // City & Location State
  bool _isCustomCity = false;
  late TextEditingController _customCityController;
  late TextEditingController _areaSectorController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isFetchingGPS = false;
  bool _isGeocoding = false;
  bool _showManualCoordinates = false;

  // Installment & Possession
  late bool _installmentAvailable;
  late bool _readyForPossession;

  // New selected image files
  File? _imageFile1;
  File? _imageFile2;
  File? _imageFile3;
  File? _imageFile4;
  File? _imageFile5;

  // Existing image URLs
  String? _existingImage1;
  String? _existingImage2;
  String? _existingImage3;
  String? _existingImage4;
  String? _existingImage5;

  // Controllers for text inputs
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _plotNumberController;
  late TextEditingController _areaSizeController;
  late TextEditingController _priceController;
  late TextEditingController _advanceAmountController;
  late TextEditingController _noOfInstallmentsController;
  late TextEditingController _monthlyInstallmentController;
  late TextEditingController _builtInYearController;
  late TextEditingController _parkingSpacesController;
  late TextEditingController _floorsController;
  late TextEditingController _emailController;
  late TextEditingController _mobileNumbersController;
  late TextEditingController _landlineController;
  late TextEditingController _videoUrlController;

  // Amenities Data
  String? _view;
  String? _otherMainFeatures;
  bool _doubleGlazedWindows = false;
  bool _centralAirConditioning = false;
  bool _centralHeating = false;

  String? _otherRooms;
  String? _servantQuarters;
  int? _kitchens;
  int? _storeRooms;
  bool _drawingRoom = false;
  bool _diningRoom = false;
  bool _studyRoom = false;
  bool _prayerRoom = false;
  bool _powderRoom = false;
  bool _gym = false;
  bool _steamRoom = false;
  bool _loungeOrSittingRoom = false;
  bool _laundryRoom = false;

  String? _otherBusinessCommunicationFacilities;
  bool _broadbandInternetAccess = false;
  bool _satelliteOrCableTvReady = false;
  bool _intercom = false;

  String? _otherCommunityFacilities;
  bool _communityLawnOrGarden = false;
  bool _communitySwimmingPool = false;
  bool _communityGym = false;
  bool _firstAidOrMedicalCentre = false;
  bool _dayCareCentre = false;
  bool _kidsPlayArea = false;
  bool _barbequeArea = false;
  bool _mosque = false;
  bool _communityCentre = false;

  String? _otherHealthcareRecreationFacilities;
  bool _lawnOrGarden = false;
  bool _swimmingPool = false;
  bool _sauna = false;
  bool _jacuzzi = false;

  String? _nearbySchools;
  String? _nearbyHospitals;
  String? _nearbyShoppingMalls;
  String? _nearbyRestaurants;
  double? _distanceFromAirportKms;
  String? _nearbyPublicTransportService;
  String? _otherNearbyPlaces;

  String? _otherFacilities;
  bool _maintenanceStaff = false;
  bool _securityStaff = false;
  bool _facilitiesForDisabled = false;

  @override
  void initState() {
    super.initState();
    final p = widget.property;

    // Normalize purpose
    final rawPurpose = (p.purpose ?? 'sell').toLowerCase();
    _purpose = (rawPurpose == 'rent') ? 'rent' : 'sell';

    // Normalize property type
    final rawType = (p.propertyType ?? 'home').toLowerCase();
    if (rawType.contains('plot')) {
      _propertyType = 'plots';
    } else if (rawType.contains('commercial')) {
      _propertyType = 'commercial';
    } else {
      _propertyType = 'home';
    }

    final validSubs = kPropertySubTypes[_propertyType] ?? ['House'];
    _subPropertyType = validSubs.contains(p.subPropertyType)
        ? p.subPropertyType!
        : validSubs.first;

    // City & Coordinates
    final rawCity = (p.city ?? 'Islamabad').trim();
    if (kPakistanCitiesCoordinates.containsKey(rawCity)) {
      _city = rawCity;
      _isCustomCity = false;
      _customCityController = TextEditingController(text: '');
    } else {
      final match = kPakistanCitiesCoordinates.keys.firstWhere(
        (k) => k.toLowerCase() == rawCity.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        _city = match;
        _isCustomCity = false;
        _customCityController = TextEditingController(text: '');
      } else {
        _city = 'Islamabad';
        _isCustomCity = true;
        _customCityController = TextEditingController(text: rawCity);
      }
    }

    if (p.latitude != null && p.latitude! >= -90.0 && p.latitude! <= 90.0) {
      _latitude = p.latitude!;
    } else {
      _latitude = kPakistanCitiesCoordinates[_city]?[0] ?? 33.6844;
    }

    if (p.longitude != null && p.longitude! >= -180.0 && p.longitude! <= 180.0) {
      _longitude = p.longitude!;
    } else {
      _longitude = kPakistanCitiesCoordinates[_city]?[1] ?? 73.0479;
    }

    _latitudeController = TextEditingController(text: _latitude.toStringAsFixed(6));
    _longitudeController = TextEditingController(text: _longitude.toStringAsFixed(6));

    // Plot Number & Area Sector splitting
    final rawPlot = p.plotNumber ?? '';
    if (rawPlot.contains(',')) {
      final parts = rawPlot.split(',');
      _plotNumberController = TextEditingController(text: parts.first.trim());
      _areaSectorController = TextEditingController(text: parts.sublist(1).join(',').trim());
    } else {
      _plotNumberController = TextEditingController(text: '');
      _areaSectorController = TextEditingController(text: rawPlot);
    }
    _areaSizeController = TextEditingController(text: p.areaSize?.toString() ?? '');
    _priceController = TextEditingController(text: p.price?.toString() ?? '');
    _advanceAmountController = TextEditingController(text: p.advanceAmount?.toString() ?? '');
    _noOfInstallmentsController = TextEditingController(text: p.noOfInstallments?.toString() ?? '');
    _monthlyInstallmentController = TextEditingController(text: p.monthlyInstallment?.toString() ?? '');
    _builtInYearController = TextEditingController(text: p.builtInYear?.toString() ?? '');
    _parkingSpacesController = TextEditingController(text: p.parkingSpaces?.toString() ?? '');
    _floorsController = TextEditingController(text: p.floors?.toString() ?? '');
    _emailController = TextEditingController(text: p.email ?? '');
    _mobileNumbersController = TextEditingController(text: p.mobileNumbers?.join(', ') ?? '');
    _landlineController = TextEditingController(text: p.landline ?? '');
    _videoUrlController = TextEditingController(text: p.videoUrl ?? p.video_url ?? '');

    // Existing Images
    _existingImage1 = p.imagePath;
    _existingImage2 = p.imagePath2;
    _existingImage3 = p.imagePath3;
    _existingImage4 = p.imagePath4;
    _existingImage5 = p.imagePath5;

    // Amenities
    _view = p.view;
    _otherMainFeatures = p.otherMainFeatures;
    _doubleGlazedWindows = p.doubleGlazedWindows ?? false;
    _centralAirConditioning = p.centralAirConditioning ?? false;
    _centralHeating = p.centralHeating ?? false;

    _otherRooms = p.otherRooms;
    _servantQuarters = p.servantQuarters;
    _kitchens = p.kitchens;
    _storeRooms = p.storeRooms;
    _drawingRoom = p.drawingRoom ?? false;
    _diningRoom = p.diningRoom ?? false;
    _studyRoom = p.studyRoom ?? false;
    _prayerRoom = p.prayerRoom ?? false;
    _powderRoom = p.powderRoom ?? false;
    _gym = p.gym ?? false;
    _steamRoom = p.steamRoom ?? false;
    _loungeOrSittingRoom = p.loungeOrSittingRoom ?? false;
    _laundryRoom = p.laundryRoom ?? false;

    _otherBusinessCommunicationFacilities = p.otherBusinessCommunicationFacilities;
    _broadbandInternetAccess = p.broadbandInternetAccess ?? false;
    _satelliteOrCableTvReady = p.satelliteOrCableTvReady ?? false;
    _intercom = p.intercom ?? false;

    _otherCommunityFacilities = p.otherCommunityFacilities;
    _communityLawnOrGarden = p.communityLawnOrGarden ?? false;
    _communitySwimmingPool = p.communitySwimmingPool ?? false;
    _communityGym = p.communityGym ?? false;
    _firstAidOrMedicalCentre = p.firstAidOrMedicalCentre ?? false;
    _dayCareCentre = p.dayCareCentre ?? false;
    _kidsPlayArea = p.kidsPlayArea ?? false;
    _barbequeArea = p.barbequeArea ?? false;
    _mosque = p.mosque ?? false;
    _communityCentre = p.communityCentre ?? false;

    _otherHealthcareRecreationFacilities = p.otherHealthcareRecreationFacilities;
    _lawnOrGarden = p.lawnOrGarden ?? false;
    _swimmingPool = p.swimmingPool ?? false;
    _sauna = p.sauna ?? false;
    _jacuzzi = p.jacuzzi ?? false;

    _nearbySchools = p.nearbySchools;
    _nearbyHospitals = p.nearbyHospitals;
    _nearbyShoppingMalls = p.nearbyShoppingMalls;
    _nearbyRestaurants = p.nearbyRestaurants;
    _distanceFromAirportKms = p.distanceFromAirportKms;
    _nearbyPublicTransportService = p.nearbyPublicTransportService;
    _otherNearbyPlaces = p.otherNearbyPlaces;

    _otherFacilities = p.otherFacilities;
    _maintenanceStaff = p.maintenanceStaff ?? false;
    _securityStaff = p.securityStaff ?? false;
    _facilitiesForDisabled = p.facilitiesForDisabled ?? false;
  }

  void _updateCityCoordinates(String cityName) {
    if (kPakistanCitiesCoordinates.containsKey(cityName)) {
      final coords = kPakistanCitiesCoordinates[cityName]!;
      setState(() {
        _latitude = coords[0];
        _longitude = coords[1];
        _latitudeController.text = _latitude.toStringAsFixed(6);
        _longitudeController.text = _longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable device location services.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied.'), backgroundColor: Colors.orange),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied permanently. Please enable in settings.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _latitudeController.text = _latitude.toStringAsFixed(6);
        _longitudeController.text = _longitude.toStringAsFixed(6);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Captured: ${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String userMsg = 'Could not get GPS location. Please check location permissions.';
        if (errStr.contains('MissingPluginException')) {
          userMsg = 'App restart required: Please stop and re-run the app to activate GPS.';
        } else if (errStr.contains('LocationServiceDisabledException')) {
          userMsg = 'Location services are disabled. Please enable GPS on your phone.';
        } else if (errStr.contains('PermissionDeniedException')) {
          userMsg = 'Location permission denied. Please allow location access.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMsg), backgroundColor: Colors.orange.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _geocodeLocation() async {
    final activeCity = _isCustomCity ? _customCityController.text.trim() : _city;
    final area = _areaSectorController.text.trim();
    if (activeCity.isEmpty && area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter City and Area / Sector first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isGeocoding = true);
    try {
      List<String> candidateQueries = [];
      if (area.isNotEmpty && activeCity.isNotEmpty) {
        candidateQueries.add('$area, $activeCity, Pakistan');
      }
      if (area.isNotEmpty) {
        candidateQueries.add('$area, Pakistan');
      }
      if (activeCity.isNotEmpty) {
        candidateQueries.add('$activeCity, Pakistan');
      }

      double? foundLat;
      double? foundLng;
      String? foundLabel;

      for (final query in candidateQueries) {
        try {
          final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
          final response = await http.get(
            url,
            headers: {
              'User-Agent': 'DharttiApp/1.0 (contact@dhartti.com)',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final List data = jsonDecode(response.body);
            if (data.isNotEmpty && data[0]['lat'] != null && data[0]['lon'] != null) {
              foundLat = double.tryParse(data[0]['lat'].toString());
              foundLng = double.tryParse(data[0]['lon'].toString());
              foundLabel = query;
              break;
            }
          }
        } catch (_) {}
      }

      // If still not found via network, check local city coordinates
      if (foundLat == null || foundLng == null) {
        if (kPakistanCitiesCoordinates.containsKey(activeCity)) {
          foundLat = kPakistanCitiesCoordinates[activeCity]![0];
          foundLng = kPakistanCitiesCoordinates[activeCity]![1];
          foundLabel = '$activeCity (City Center)';
        }
      }

      if (foundLat != null && foundLng != null) {
        setState(() {
          _latitude = foundLat!;
          _longitude = foundLng!;
          _latitudeController.text = _latitude.toStringAsFixed(6);
          _longitudeController.text = _longitude.toStringAsFixed(6);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-Pinned: $foundLabel'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not pin exact location. You can edit Lat/Lng directly.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geocoding error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _customCityController.dispose();
    _areaSectorController.dispose();
    _plotNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _areaSizeController.dispose();
    _priceController.dispose();
    _advanceAmountController.dispose();
    _noOfInstallmentsController.dispose();
    _monthlyInstallmentController.dispose();
    _builtInYearController.dispose();
    _parkingSpacesController.dispose();
    _floorsController.dispose();
    _emailController.dispose();
    _mobileNumbersController.dispose();
    _landlineController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int imageNumber) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (imageNumber) {
            case 1: _imageFile1 = File(pickedFile.path); break;
            case 2: _imageFile2 = File(pickedFile.path); break;
            case 3: _imageFile3 = File(pickedFile.path); break;
            case 4: _imageFile4 = File(pickedFile.path); break;
            case 5: _imageFile5 = File(pickedFile.path); break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int imageNumber) {
    setState(() {
      switch (imageNumber) {
        case 1: _imageFile1 = null; _existingImage1 = null; break;
        case 2: _imageFile2 = null; _existingImage2 = null; break;
        case 3: _imageFile3 = null; _existingImage3 = null; break;
        case 4: _imageFile4 = null; _existingImage4 = null; break;
        case 5: _imageFile5 = null; _existingImage5 = null; break;
      }
    });
  }

  Future<void> _submitUpdateForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double areaSize = double.tryParse(_areaSizeController.text.trim()) ?? 0.0;
      final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final int? builtInYear = int.tryParse(_builtInYearController.text.trim());
      final int? parkingSpaces = int.tryParse(_parkingSpacesController.text.trim());
      final int? floors = int.tryParse(_floorsController.text.trim());

      final double? advanceAmount = _installmentAvailable
          ? double.tryParse(_advanceAmountController.text.trim())
          : null;
      final int? noOfInstallments = _installmentAvailable
          ? int.tryParse(_noOfInstallmentsController.text.trim())
          : null;
      final double? monthlyInstallment = _installmentAvailable
          ? double.tryParse(_monthlyInstallmentController.text.trim())
          : null;

      final List<String> mobileNumbers = _mobileNumbersController.text.isEmpty
          ? []
          : _mobileNumbersController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      final String effectiveCity = _isCustomCity && _customCityController.text.trim().isNotEmpty
          ? _customCityController.text.trim()
          : _city;

      final String areaPart = _areaSectorController.text.trim();
      final String plotPart = _plotNumberController.text.trim();
      String? combinedPlotNumber;
      if (plotPart.isNotEmpty && areaPart.isNotEmpty) {
        combinedPlotNumber = '$plotPart, $areaPart';
      } else if (areaPart.isNotEmpty) {
        combinedPlotNumber = areaPart;
      } else if (plotPart.isNotEmpty) {
        combinedPlotNumber = plotPart;
      }

      final double finalLat = double.tryParse(_latitudeController.text.trim()) ?? _latitude;
      final double finalLng = double.tryParse(_longitudeController.text.trim()) ?? _longitude;

      Property updatedProperty = Property(
        id: widget.property.id,
        purpose: _purpose,
        propertyType: _propertyType,
        subPropertyType: _subPropertyType,
        city: effectiveCity,
        latitude: finalLat,
        longitude: finalLng,
        plotNumber: combinedPlotNumber,
        areaSize: areaSize,
        areaUnit: _areaUnit,
        price: price,
        currency: _currency,
        installmentAvailable: _installmentAvailable,
        advanceAmount: advanceAmount,
        noOfInstallments: noOfInstallments,
        monthlyInstallment: monthlyInstallment,
        readyForPossession: _readyForPossession,
        bedrooms: _propertyType == 'plots' ? 0 : _bedrooms,
        bathrooms: _propertyType == 'plots' ? 0 : _bathrooms,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumbers: mobileNumbers.isNotEmpty ? mobileNumbers : null,
        whatsappNumber: mobileNumbers.isNotEmpty ? mobileNumbers.first : null,
        landline: _landlineController.text.trim().isNotEmpty
            ? _landlineController.text.trim()
            : null,
        video_url: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        videoUrl: _videoUrlController.text.trim().isNotEmpty
            ? _videoUrlController.text.trim()
            : null,
        imagePath: _existingImage1,
        imagePath2: _existingImage2,
        imagePath3: _existingImage3,
        imagePath4: _existingImage4,
        imagePath5: _existingImage5,
        flooring: _flooring,
        electricityBackup: _electricityBackup,
        view: _view,
        otherMainFeatures: _otherMainFeatures,
        builtInYear: builtInYear,
        parkingSpaces: parkingSpaces,
        floors: floors,
        doubleGlazedWindows: _doubleGlazedWindows,
        centralAirConditioning: _centralAirConditioning,
        centralHeating: _centralHeating,
        otherRooms: _otherRooms,
        servantQuarters: _servantQuarters,
        kitchens: _kitchens,
        storeRooms: _storeRooms,
        drawingRoom: _drawingRoom,
        diningRoom: _diningRoom,
        studyRoom: _studyRoom,
        prayerRoom: _prayerRoom,
        powderRoom: _powderRoom,
        gym: _gym,
        steamRoom: _steamRoom,
        loungeOrSittingRoom: _loungeOrSittingRoom,
        laundryRoom: _laundryRoom,
        otherBusinessCommunicationFacilities: _otherBusinessCommunicationFacilities,
        broadbandInternetAccess: _broadbandInternetAccess,
        satelliteOrCableTvReady: _satelliteOrCableTvReady,
        intercom: _intercom,
        otherCommunityFacilities: _otherCommunityFacilities,
        communityLawnOrGarden: _communityLawnOrGarden,
        communitySwimmingPool: _communitySwimmingPool,
        communityGym: _communityGym,
        firstAidOrMedicalCentre: _firstAidOrMedicalCentre,
        dayCareCentre: _dayCareCentre,
        kidsPlayArea: _kidsPlayArea,
        barbequeArea: _barbequeArea,
        mosque: _mosque,
        communityCentre: _communityCentre,
        otherHealthcareRecreationFacilities: _otherHealthcareRecreationFacilities,
        lawnOrGarden: _lawnOrGarden,
        swimmingPool: _swimmingPool,
        sauna: _sauna,
        jacuzzi: _jacuzzi,
        nearbySchools: _nearbySchools,
        nearbyHospitals: _nearbyHospitals,
        nearbyShoppingMalls: _nearbyShoppingMalls,
        nearbyRestaurants: _nearbyRestaurants,
        distanceFromAirportKms: _distanceFromAirportKms,
        nearbyPublicTransportService: _nearbyPublicTransportService,
        otherNearbyPlaces: _otherNearbyPlaces,
        otherFacilities: _otherFacilities,
        maintenanceStaff: _maintenanceStaff,
        securityStaff: _securityStaff,
        facilitiesForDisabled: _facilitiesForDisabled,
      );

      bool isUpdated = await PropertyService().updateProperty(
        updatedProperty,
        image1: _imageFile1,
        image2: _imageFile2,
        image3: _imageFile3,
        image4: _imageFile4,
        image5: _imageFile5,
      );

      if (isUpdated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update property.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _countActiveAmenities() {
    int count = 0;
    if (_doubleGlazedWindows) count++;
    if (_centralAirConditioning) count++;
    if (_centralHeating) count++;
    if (_drawingRoom) count++;
    if (_diningRoom) count++;
    if (_studyRoom) count++;
    if (_prayerRoom) count++;
    if (_powderRoom) count++;
    if (_gym) count++;
    if (_steamRoom) count++;
    if (_loungeOrSittingRoom) count++;
    if (_laundryRoom) count++;
    if (_broadbandInternetAccess) count++;
    if (_satelliteOrCableTvReady) count++;
    if (_intercom) count++;
    if (_communityLawnOrGarden) count++;
    if (_communitySwimmingPool) count++;
    if (_communityGym) count++;
    if (_firstAidOrMedicalCentre) count++;
    if (_dayCareCentre) count++;
    if (_kidsPlayArea) count++;
    if (_barbequeArea) count++;
    if (_mosque) count++;
    if (_communityCentre) count++;
    if (_lawnOrGarden) count++;
    if (_swimmingPool) count++;
    if (_sauna) count++;
    if (_jacuzzi) count++;
    if (_maintenanceStaff) count++;
    if (_securityStaff) count++;
    if (_facilitiesForDisabled) count++;
    return count;
  }

  void _openAmenitiesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: DefaultTabController(
                length: 7,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Property Amenities',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelColor: Colors.green.shade700,
                      indicatorColor: Colors.green.shade700,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Features"),
                        Tab(text: "Rooms"),
                        Tab(text: "Business"),
                        Tab(text: "Community"),
                        Tab(text: "Healthcare"),
                        Tab(text: "Nearby"),
                        Tab(text: "Facilities"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Features
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _view,
                                label: "Scenic View",
                                onChanged: (val) => modalSetState(() => _view = val),
                              ),
                              _buildTextInputField(
                                value: _otherMainFeatures,
                                label: "Other Main Features",
                                onChanged: (val) => modalSetState(() => _otherMainFeatures = val),
                              ),
                              _buildCheckboxField(
                                value: _doubleGlazedWindows,
                                label: "Double Glazed Windows",
                                onChanged: (val) => modalSetState(() => _doubleGlazedWindows = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _centralAirConditioning,
                                label: "Central Air Conditioning",
                                onChanged: (val) => modalSetState(() => _centralAirConditioning = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _centralHeating,
                                label: "Central Heating",
                                onChanged: (val) => modalSetState(() => _centralHeating = val ?? false),
                              ),
                            ],
                          ),
                          // Tab 2: Rooms
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _otherRooms,
                                label: "Other Rooms",
                                onChanged: (val) => modalSetState(() => _otherRooms = val),
                              ),
                              _buildTextInputField(
                                value: _servantQuarters,
                                label: "Servant Quarters",
                                onChanged: (val) => modalSetState(() => _servantQuarters = val),
                              ),
                              _buildNumberInputField(
                                value: _kitchens,
                                label: "Number of Kitchens",
                                onChanged: (val) => modalSetState(() => _kitchens = val),
                              ),
                              _buildNumberInputField(
                                value: _storeRooms,
                                label: "Store Rooms",
                                onChanged: (val) => modalSetState(() => _storeRooms = val),
                              ),
                              _buildCheckboxField(
                                value: _drawingRoom,
                                label: "Drawing Room",
                                onChanged: (val) => modalSetState(() => _drawingRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _diningRoom,
                                label: "Dining Room",
                                onChanged: (val) => modalSetState(() => _diningRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _studyRoom,
                                label: "Study Room",
                                onChanged: (val) => modalSetState(() => _studyRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _prayerRoom,
                                label: "Prayer Room",
                                onChanged: (val) => modalSetState(() => _prayerRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _powderRoom,
                                label: "Powder Room",
                                onChanged: (val) => modalSetState(() => _powderRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _gym,
                                label: "Private Gym",
                                onChanged: (val) => modalSetState(() => _gym = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _steamRoom,
                                label: "Steam Room",
                                onChanged: (val) => modalSetState(() => _steamRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _loungeOrSittingRoom,
                                label: "Lounge / Sitting Room",
                                onChanged: (val) => modalSetState(() => _loungeOrSittingRoom = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _laundryRoom,
                                label: "Laundry Room",
                                onChanged: (val) => modalSetState(() => _laundryRoom = val ?? false),
                              ),
                            ],
                          ),
                          // Tab 3: Business
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _otherBusinessCommunicationFacilities,
                                label: "Other Business Facilities",
                                onChanged: (val) => modalSetState(() => _otherBusinessCommunicationFacilities = val),
                              ),
                              _buildCheckboxField(
                                value: _broadbandInternetAccess,
                                label: "Broadband Internet Access",
                                onChanged: (val) => modalSetState(() => _broadbandInternetAccess = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _satelliteOrCableTvReady,
                                label: "Satellite / Cable TV Ready",
                                onChanged: (val) => modalSetState(() => _satelliteOrCableTvReady = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _intercom,
                                label: "Intercom",
                                onChanged: (val) => modalSetState(() => _intercom = val ?? false),
                              ),
                            ],
                          ),
                          // Tab 4: Community
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _otherCommunityFacilities,
                                label: "Other Community Facilities",
                                onChanged: (val) => modalSetState(() => _otherCommunityFacilities = val),
                              ),
                              _buildCheckboxField(
                                value: _communityLawnOrGarden,
                                label: "Community Lawn / Garden",
                                onChanged: (val) => modalSetState(() => _communityLawnOrGarden = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _communitySwimmingPool,
                                label: "Community Swimming Pool",
                                onChanged: (val) => modalSetState(() => _communitySwimmingPool = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _communityGym,
                                label: "Community Gym",
                                onChanged: (val) => modalSetState(() => _communityGym = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _firstAidOrMedicalCentre,
                                label: "First Aid / Medical Centre",
                                onChanged: (val) => modalSetState(() => _firstAidOrMedicalCentre = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _dayCareCentre,
                                label: "Day Care Centre",
                                onChanged: (val) => modalSetState(() => _dayCareCentre = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _kidsPlayArea,
                                label: "Kids Play Area",
                                onChanged: (val) => modalSetState(() => _kidsPlayArea = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _barbequeArea,
                                label: "Barbeque Area",
                                onChanged: (val) => modalSetState(() => _barbequeArea = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _mosque,
                                label: "Mosque in Society",
                                onChanged: (val) => modalSetState(() => _mosque = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _communityCentre,
                                label: "Community Centre",
                                onChanged: (val) => modalSetState(() => _communityCentre = val ?? false),
                              ),
                            ],
                          ),
                          // Tab 5: Healthcare
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _otherHealthcareRecreationFacilities,
                                label: "Other Healthcare Facilities",
                                onChanged: (val) => modalSetState(() => _otherHealthcareRecreationFacilities = val),
                              ),
                              _buildCheckboxField(
                                value: _lawnOrGarden,
                                label: "Private Lawn / Garden",
                                onChanged: (val) => modalSetState(() => _lawnOrGarden = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _swimmingPool,
                                label: "Private Swimming Pool",
                                onChanged: (val) => modalSetState(() => _swimmingPool = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _sauna,
                                label: "Sauna",
                                onChanged: (val) => modalSetState(() => _sauna = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _jacuzzi,
                                label: "Jacuzzi",
                                onChanged: (val) => modalSetState(() => _jacuzzi = val ?? false),
                              ),
                            ],
                          ),
                          // Tab 6: Nearby
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _nearbySchools,
                                label: "Nearby Schools",
                                onChanged: (val) => modalSetState(() => _nearbySchools = val),
                              ),
                              _buildTextInputField(
                                value: _nearbyHospitals,
                                label: "Nearby Hospitals",
                                onChanged: (val) => modalSetState(() => _nearbyHospitals = val),
                              ),
                              _buildTextInputField(
                                value: _nearbyShoppingMalls,
                                label: "Nearby Shopping Malls",
                                onChanged: (val) => modalSetState(() => _nearbyShoppingMalls = val),
                              ),
                              _buildTextInputField(
                                value: _nearbyRestaurants,
                                label: "Nearby Restaurants",
                                onChanged: (val) => modalSetState(() => _nearbyRestaurants = val),
                              ),
                              _buildTextInputField(
                                value: _nearbyPublicTransportService,
                                label: "Nearby Public Transport",
                                onChanged: (val) => modalSetState(() => _nearbyPublicTransportService = val),
                              ),
                              _buildTextInputField(
                                value: _otherNearbyPlaces,
                                label: "Other Nearby Places",
                                onChanged: (val) => modalSetState(() => _otherNearbyPlaces = val),
                              ),
                            ],
                          ),
                          // Tab 7: Facilities
                          _buildAmenitiesTab(
                            children: [
                              _buildTextInputField(
                                value: _otherFacilities,
                                label: "Other Facilities",
                                onChanged: (val) => modalSetState(() => _otherFacilities = val),
                              ),
                              _buildCheckboxField(
                                value: _maintenanceStaff,
                                label: "Maintenance Staff",
                                onChanged: (val) => modalSetState(() => _maintenanceStaff = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _securityStaff,
                                label: "24/7 Security Staff",
                                onChanged: (val) => modalSetState(() => _securityStaff = val ?? false),
                              ),
                              _buildCheckboxField(
                                value: _facilitiesForDisabled,
                                label: "Facilities for Disabled",
                                onChanged: (val) => modalSetState(() => _facilitiesForDisabled = val ?? false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAmenitiesTab({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextInputField({
    required String? value,
    required String label,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (val) => onChanged(val.trim().isEmpty ? null : val.trim()),
      ),
    );
  }

  Widget _buildNumberInputField({
    required int? value,
    required String label,
    required Function(int?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value?.toString(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        keyboardType: TextInputType.number,
        style: GoogleFonts.poppins(fontSize: 13),
        onChanged: (val) => onChanged(int.tryParse(val)),
      ),
    );
  }

  Widget _buildCheckboxField({
    required bool value,
    required String label,
    required Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          title: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green.shade700,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          dense: true,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            style: GoogleFonts.poppins(color: Colors.grey.shade900, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.green.shade700, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
              prefixIcon: Icon(icon, color: Colors.green.shade700, size: 18),
              prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: maxLines > 1 ? 12 : 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}/uploads/property/${path.replaceAll('/uploads/property/', '')}';
  }

  Widget _buildPhotoSlot({
    required int index,
    required String label,
    required File? imageFile,
    required String? existingUrl,
    bool isPrimary = false,
  }) {
    final bool hasImage = imageFile != null || (existingUrl != null && existingUrl.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: isPrimary ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeImage(index),
                child: Text(
                  'Remove',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            height: isPrimary ? 140 : 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasImage ? Colors.green.shade600 : Colors.grey.shade300,
                width: hasImage ? 1.5 : 1,
              ),
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: isPrimary ? 34 : 26,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrimary ? 'Tap to upload Cover Photo' : 'Tap to upload Image $index',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageFile != null)
                          Image.file(imageFile, fit: BoxFit.cover)
                        else
                          Image.network(
                            _formatImageUrl(existingUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                            ),
                          ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentSubTypes = kPropertySubTypes[_propertyType] ?? ['House'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          'Edit Property',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: PROPERTY BASICS
                _buildSectionCard(
                  title: 'Property Basics',
                  icon: Icons.home_work_outlined,
                  children: [
                    // Purpose Dropdown
                    _buildDropdown<String>(
                      label: 'Purpose',
                      value: _purpose,
                      icon: Icons.sell_outlined,
                      items: const [
                        DropdownMenuItem(value: 'sell', child: Text('For Sale')),
                        DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _purpose = val);
                      },
                    ),

                    // Property Type Dropdown
                    _buildDropdown<String>(
                      label: 'Property Type',
                      value: _propertyType,
                      icon: Icons.category_outlined,
                      items: const [
                        DropdownMenuItem(value: 'home', child: Text('Home')),
                        DropdownMenuItem(value: 'plots', child: Text('Plots')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _propertyType = val;
                            final newSubTypes = kPropertySubTypes[_propertyType] ?? ['House'];
                            if (!newSubTypes.contains(_subPropertyType)) {
                              _subPropertyType = newSubTypes.first;
                            }
                          });
                        }
                      },
                    ),

                    // Sub Property Type Dropdown (Dynamic)
                    _buildDropdown<String>(
                      label: 'Sub Property Type',
                      value: currentSubTypes.contains(_subPropertyType)
                          ? _subPropertyType
                          : currentSubTypes.first,
                      icon: Icons.maps_home_work_outlined,
                      items: currentSubTypes
                          .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _subPropertyType = val);
                      },
                    ),

                    // Property Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Property Title *',
                      hint: 'e.g. Beautiful 10 Marla Brand New Modern House',
                      icon: Icons.title,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter property title'
                          : null,
                    ),

                    // Property Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Property Description *',
                      hint: 'Describe features, finishing, location advantages...',
                      icon: Icons.notes,
                      maxLines: 4,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter description'
                          : null,
                    ),
                  ],
                ),

                // SECTION 2: LOCATION & ADDRESS
                _buildSectionCard(
                  title: 'Location & Address',
                  icon: Icons.location_on_outlined,
                  children: [
                    // City Dropdown
                    _buildDropdown<String>(
                      label: 'City *',
                      value: _isCustomCity
                          ? 'other'
                          : (kPakistanCitiesCoordinates.containsKey(_city) ? _city : 'Islamabad'),
                      icon: Icons.location_city,
                      items: [
                        ...kPakistanCitiesCoordinates.keys.map(
                          (cityName) => DropdownMenuItem(value: cityName, child: Text(cityName)),
                        ),
                        const DropdownMenuItem(
                          value: 'other',
                          child: Text('+ Other (Enter Custom City)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (val == 'other') {
                              _isCustomCity = true;
                            } else {
                              _isCustomCity = false;
                              _city = val;
                              _updateCityCoordinates(val);
                            }
                          });
                        }
                      },
                    ),

                    // Custom City Input (if 'Other' is chosen)
                    if (_isCustomCity) ...[
                      _buildTextField(
                        controller: _customCityController,
                        label: 'Enter Custom City Name *',
                        hint: 'e.g. Swat, Taxila, Kohat, Hafizabad...',
                        icon: Icons.edit_location_alt_outlined,
                        validator: (val) {
                          if (_isCustomCity && (val == null || val.trim().isEmpty)) {
                            return 'Please enter city name';
                          }
                          return null;
                        },
                      ),
                    ],

                    // Dedicated Area / Society / Sector Field
                    _buildTextField(
                      controller: _areaSectorController,
                      label: 'Area / Society / Sector *',
                      hint: 'e.g. DHA Phase 6, Bahria Town, Gulberg III, F-10/2',
                      icon: Icons.maps_home_work_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter area, society or sector';
                        }
                        return null;
                      },
                    ),

                    // Dedicated House / Street / Plot #
                    _buildTextField(
                      controller: _plotNumberController,
                      label: 'House / Street / Plot # (Optional)',
                      hint: 'e.g. House #14, Street #21, Plot #52',
                      icon: Icons.pin_drop_outlined,
                    ),

                    // Geolocation & GPS Action Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.green.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Coordinates: ${_latitude.toStringAsFixed(4)}° N, ${_longitude.toStringAsFixed(4)}° E',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // GPS Button
                              ElevatedButton.icon(
                                onPressed: _isFetchingGPS ? null : _getCurrentLocation,
                                icon: _isFetchingGPS
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.my_location, size: 15, color: Colors.white),
                                label: Text(
                                  'Use Device GPS',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              // OpenCage Geocoder Button
                              OutlinedButton.icon(
                                onPressed: _isGeocoding ? null : _geocodeLocation,
                                icon: _isGeocoding
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green.shade800),
                                      )
                                    : Icon(Icons.travel_explore, size: 15, color: Colors.green.shade800),
                                label: Text(
                                  'Auto-Pin Address',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.shade700),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              // Manual Coordinates Toggle
                              TextButton(
                                onPressed: () => setState(() => _showManualCoordinates = !_showManualCoordinates),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _showManualCoordinates ? 'Hide Lat/Lng' : 'Edit Lat/Lng',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          if (_showManualCoordinates) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latitudeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                    decoration: InputDecoration(
                                      labelText: 'Latitude',
                                      labelStyle: GoogleFonts.poppins(fontSize: 11),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (v) {
                                      final parsed = double.tryParse(v);
                                      if (parsed != null) setState(() => _latitude = parsed);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _longitudeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                    decoration: InputDecoration(
                                      labelText: 'Longitude',
                                      labelStyle: GoogleFonts.poppins(fontSize: 11),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (v) {
                                      final parsed = double.tryParse(v);
                                      if (parsed != null) setState(() => _longitude = parsed);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // SECTION 3: PRICING & INSTALLMENTS
                _buildSectionCard(
                  title: 'Price & Installment Details',
                  icon: Icons.attach_money_outlined,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price *',
                            hint: 'e.g. 15000000',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter price';
                              if (double.tryParse(val.trim()) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildDropdown<String>(
                            label: 'Currency',
                            value: _currency,
                            icon: Icons.currency_exchange,
                            items: const [
                              DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs)')),
                              DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                              DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                              DropdownMenuItem(value: 'AED', child: Text('AED (د.إ)')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _currency = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    // Installment Toggle
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          title: Text(
                            'Installment Available',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          value: _installmentAvailable,
                          activeColor: Colors.green.shade700,
                          onChanged: (val) => setState(() => _installmentAvailable = val),
                        ),
                      ),
                    ),

                    // Conditional Installment Fields
                    if (_installmentAvailable) ...[
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _advanceAmountController,
                        label: 'Advance / Down Payment',
                        hint: 'e.g. 2000000',
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _noOfInstallmentsController,
                              label: 'No. of Installments',
                              hint: 'e.g. 24',
                              icon: Icons.format_list_numbered,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _monthlyInstallmentController,
                              label: 'Monthly Amount',
                              hint: 'e.g. 50000',
                              icon: Icons.calendar_month_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Ready for Possession Toggle
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Material(
                        color: const Color(0xFFF9FAFB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          title: Text(
                            'Ready For Possession',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          value: _readyForPossession,
                          activeColor: Colors.green.shade700,
                          onChanged: (val) => setState(() => _readyForPossession = val),
                        ),
                      ),
                    ),
                  ],
                ),

                // SECTION 4: SPECIFICATIONS & FEATURES
                _buildSectionCard(
                  title: 'Specifications & Features',
                  icon: Icons.straighten_outlined,
                  children: [
                    // Area Size + Area Unit Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _areaSizeController,
                            label: 'Area Size *',
                            hint: 'e.g. 5, 10, 1',
                            icon: Icons.aspect_ratio,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter area';
                              if (double.tryParse(val.trim()) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildDropdown<String>(
                            label: 'Area Unit',
                            value: _areaUnit,
                            icon: Icons.square_foot,
                            items: const [
                              DropdownMenuItem(value: 'marla', child: Text('Marla')),
                              DropdownMenuItem(value: 'kanal', child: Text('Kanal')),
                              DropdownMenuItem(value: 'sqft', child: Text('Sq. Feet')),
                              DropdownMenuItem(value: 'sqyd', child: Text('Sq. Yards')),
                              DropdownMenuItem(value: 'sqm', child: Text('Sq. Meter')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _areaUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    // Bedrooms & Bathrooms (Only if not Plots)
                    if (_propertyType != 'plots')
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<int>(
                              label: 'Bedrooms',
                              value: _bedrooms,
                              icon: Icons.bed_outlined,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Studio / 0')),
                                DropdownMenuItem(value: 1, child: Text('1 Bed')),
                                DropdownMenuItem(value: 2, child: Text('2 Beds')),
                                DropdownMenuItem(value: 3, child: Text('3 Beds')),
                                DropdownMenuItem(value: 4, child: Text('4 Beds')),
                                DropdownMenuItem(value: 5, child: Text('5 Beds')),
                                DropdownMenuItem(value: 6, child: Text('6 Beds')),
                                DropdownMenuItem(value: 7, child: Text('7+ Beds')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _bedrooms = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown<int>(
                              label: 'Bathrooms',
                              value: _bathrooms,
                              icon: Icons.bathtub_outlined,
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('1 Bath')),
                                DropdownMenuItem(value: 2, child: Text('2 Baths')),
                                DropdownMenuItem(value: 3, child: Text('3 Baths')),
                                DropdownMenuItem(value: 4, child: Text('4 Baths')),
                                DropdownMenuItem(value: 5, child: Text('5 Baths')),
                                DropdownMenuItem(value: 6, child: Text('6 Baths')),
                                DropdownMenuItem(value: 7, child: Text('7+ Baths')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _bathrooms = val);
                              },
                            ),
                          ),
                        ],
                      ),

                    // Flooring & Electricity Backup
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown<String>(
                            label: 'Flooring',
                            value: _flooring,
                            icon: Icons.layers_outlined,
                            items: const [
                              DropdownMenuItem(value: 'Tiles', child: Text('Tiles')),
                              DropdownMenuItem(value: 'Wood', child: Text('Wood')),
                              DropdownMenuItem(value: 'Carpet', child: Text('Carpet')),
                              DropdownMenuItem(value: 'Marble', child: Text('Marble')),
                              DropdownMenuItem(value: 'Mosaic', child: Text('Mosaic')),
                              DropdownMenuItem(value: 'None', child: Text('None')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _flooring = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown<String>(
                            label: 'Electricity Backup',
                            value: _electricityBackup,
                            icon: Icons.bolt_outlined,
                            items: const [
                              DropdownMenuItem(value: 'None', child: Text('None')),
                              DropdownMenuItem(value: 'Generator', child: Text('Generator')),
                              DropdownMenuItem(value: 'Solar', child: Text('Solar')),
                              DropdownMenuItem(value: 'UPS', child: Text('UPS')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _electricityBackup = val);
                            },
                          ),
                        ),
                      ],
                    ),

                    // Built in Year, Floors, Parking Spaces
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _builtInYearController,
                            label: 'Year Built',
                            hint: 'e.g. 2024',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _floorsController,
                            label: 'Floors',
                            hint: 'e.g. 2',
                            icon: Icons.stairs_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _parkingSpacesController,
                      label: 'Parking Spaces',
                      hint: 'e.g. 2',
                      icon: Icons.directions_car_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                // SECTION 5: MEDIA & PHOTOS
                _buildSectionCard(
                  title: 'Photos & Media',
                  icon: Icons.photo_library_outlined,
                  children: [
                    _buildPhotoSlot(
                      index: 1,
                      label: 'Primary Cover Photo',
                      imageFile: _imageFile1,
                      existingUrl: _existingImage1,
                      isPrimary: true,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoSlot(
                            index: 2,
                            label: 'Secondary Photo 1',
                            imageFile: _imageFile2,
                            existingUrl: _existingImage2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPhotoSlot(
                            index: 3,
                            label: 'Secondary Photo 2',
                            imageFile: _imageFile3,
                            existingUrl: _existingImage3,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoSlot(
                            index: 4,
                            label: 'Secondary Photo 3',
                            imageFile: _imageFile4,
                            existingUrl: _existingImage4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPhotoSlot(
                            index: 5,
                            label: 'Secondary Photo 4',
                            imageFile: _imageFile5,
                            existingUrl: _existingImage5,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _videoUrlController,
                      label: 'Video Link (YouTube / Vimeo)',
                      hint: 'https://youtube.com/watch?v=...',
                      icon: Icons.smart_display_outlined,
                    ),
                  ],
                ),

                // SECTION 6: CONTACT INFORMATION
                _buildSectionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: 'Contact Email *',
                      hint: 'your.email@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter email';
                        if (!val.contains('@')) return 'Enter valid email';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _mobileNumbersController,
                      label: 'Contact Phone / WhatsApp *',
                      hint: '03001234567, 03211234567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter contact number';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _landlineController,
                      label: 'Landline Number (Optional)',
                      hint: 'e.g. 051-1234567',
                      icon: Icons.phone_in_talk_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                // SECTION 7: FULL AMENITIES MODAL BUTTON
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openAmenitiesModal,
                    icon: Icon(Icons.tune, color: Colors.green.shade700),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Configure Amenities',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                          if (_countActiveAmenities() > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_countActiveAmenities()} selected',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.green.shade700, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.green.shade50.withOpacity(0.5),
                    ),
                  ),
                ),

                // SUBMIT UPDATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitUpdateForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Update Property',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
