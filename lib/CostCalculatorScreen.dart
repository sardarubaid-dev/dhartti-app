import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:dhartti/constants.dart';
import 'package:dhartti/Model/ConstructionCostModel.dart';
import 'package:dhartti/ResultScreen.dart';
import 'package:dhartti/service/construction_cost_service.dart';

class CostCalculatorForm extends StatefulWidget {
  const CostCalculatorForm({Key? key}) : super(key: key);

  @override
  _CostCalculatorFormState createState() => _CostCalculatorFormState();
}

class _CostCalculatorFormState extends State<CostCalculatorForm> {
  final _formKey = GlobalKey<FormState>();

  List<String> cities = [
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Karachi',
    'Faisalabad',
    'Multan',
    'Peshawar',
  ];

  String? selectedCity = 'Lahore';
  final TextEditingController _areaController = TextEditingController(text: '5');
  final TextEditingController _coveredAreaController = TextEditingController();

  String unit = 'Marla';
  String structureType = 'complete'; // 'grey' or 'complete'
  String constructionMode = 'with_material'; // 'with_material' or 'without_material'

  int bedrooms = 3;
  int bathrooms = 3;
  int kitchens = 1;
  int drawingRooms = 1;
  int livingRooms = 1;
  int floors = 2;

  bool isLoading = false;

  static const Color dharttiGreen = Color(0xFF108224);

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _coveredAreaController.dispose();
    super.dispose();
  }

  Future<void> _fetchCities() async {
    try {
      final List<ConstructionCostModel> costData = await ConstructionCostService.getAll();
      final uniqueCities = costData.map((e) => e.city).where((c) => c.isNotEmpty).toSet().toList();
      if (uniqueCities.isNotEmpty && mounted) {
        setState(() {
          for (var c in uniqueCities) {
            if (!cities.contains(c)) cities.add(c);
          }
          if (!cities.contains(selectedCity)) {
            selectedCity = cities.first;
          }
        });
      }
    } catch (_) {
      // Keep robust defaults
    }
  }

  Map<String, dynamic> _calculateLocalEstimate({
    required String city,
    required double areaVal,
    required String unitVal,
    required String structureVal,
    required String modeVal,
    required int bed,
    required int bath,
    required int kit,
    required int draw,
    required int liv,
    required int flr,
    double? customCoveredArea,
  }) {
    final sqft = (unitVal == 'Kanal') ? areaVal * 5445 : areaVal * 272.25;
    final extraSqft = (bed * 120 + bath * 80 + kit * 60 + draw * 100 + liv * 150);
    final coveredArea = customCoveredArea ?? (((sqft * 0.8) + extraSqft) * flr);

    const greyMaterialRate = 2400.0;
    const finishingMaterialRate = 1700.0;
    final laborRate = (modeVal == 'with_material') ? 500.0 : 300.0;

    final greyCost = greyMaterialRate * coveredArea;
    final labourCost = laborRate * coveredArea;
    final finishCost = (structureVal == 'complete') ? finishingMaterialRate * coveredArea : 0.0;

    final totalCost = (modeVal == 'with_material')
        ? greyCost + labourCost + finishCost
        : labourCost;

    final pricePerSqft = totalCost / (coveredArea > 0 ? coveredArea : 1);

    final greyBreakdown = {
      'Foundation': 0.20,
      'Walls & Structure': 0.35,
      'Roof & Slabs': 0.15,
      'Plumbing': 0.10,
      'Electrical': 0.10,
      'External Works': 0.10,
    };

    final breakdownData = <String, dynamic>{};
    greyBreakdown.forEach((label, fraction) {
      breakdownData[label] = {
        'lakh': (greyCost * fraction) / 100000,
        'percent': (fraction * 100).toDouble(),
      };
    });

    return {
      'grey_cost': greyCost,
      'labour_cost': labourCost,
      'finish_cost': finishCost,
      'total_cost': totalCost,
      'price_per_sqft': pricePerSqft,
      'covered_area': coveredArea,
      'breakdown_data': breakdownData,
      'city_rates': {
        'grey_material': greyMaterialRate,
        'finishing_material': finishingMaterialRate,
        'labour': laborRate,
      },
      'inputs': {
        'city': city,
        'area': areaVal,
        'unit': unitVal,
        'structure_type': structureVal,
        'construction_mode': modeVal,
        'bedrooms': bed,
        'bathrooms': bath,
        'kitchens': kit,
        'drawing_rooms': draw,
        'living_rooms': liv,
        'floors': flr,
      },
    };
  }

  Future<void> _calculateCost() async {
    if (!_formKey.currentState!.validate()) return;

    final areaVal = double.tryParse(_areaController.text) ?? 5.0;
    final coveredVal = double.tryParse(_coveredAreaController.text);

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/calculate-cost'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'city': selectedCity ?? 'Lahore',
          'area': areaVal,
          'unit': unit,
          'structure_type': structureType,
          'construction_mode': constructionMode,
          'bedrooms': bedrooms,
          'bathrooms': bathrooms,
          'kitchens': kitchens,
          'drawing_rooms': drawingRooms,
          'living_rooms': livingRooms,
          'floors': floors,
          if (coveredVal != null) 'covered_area': coveredVal,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CostResultsScreen(result: result['data']),
            ),
          );
        }
        return;
      }
    } catch (_) {
      // Fallback seamlessly to local computation so calculation never fails
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }

    // Local calculation fallback if server is unreachable
    final localData = _calculateLocalEstimate(
      city: selectedCity ?? 'Lahore',
      areaVal: areaVal,
      unitVal: unit,
      structureVal: structureType,
      modeVal: constructionMode,
      bed: bedrooms,
      bath: bathrooms,
      kit: kitchens,
      draw: drawingRooms,
      liv: livingRooms,
      flr: floors,
      customCoveredArea: coveredVal,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CostResultsScreen(result: localData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Construction Cost Calculator',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: dharttiGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [dharttiGreen, Colors.green.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Cost Estimator',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Get real-time market rates for grey structure & complete finishing in Pakistan.',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Location & Size
              _buildSectionHeader('1. Location & Plot Size', Icons.location_city_rounded),
              _buildCardContainer([
                // City Dropdown
                Text(
                  'Select City',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: dharttiGreen, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                  onChanged: (val) => setState(() => selectedCity = val),
                ),
                const SizedBox(height: 14),

                // Plot Area & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plot Area',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _areaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: 'e.g. 5 or 10',
                              prefixIcon: const Icon(Icons.square_foot_rounded, color: dharttiGreen, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: unit,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dharttiGreen, width: 1.5)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: ['Marla', 'Kanal'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                            onChanged: (val) => setState(() => unit = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // Section 2: Construction Scope
              _buildSectionHeader('2. Construction Scope', Icons.construction_rounded),
              _buildCardContainer([
                Text(
                  'Project Finish Type',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOptionChip(
                      label: 'Complete House',
                      subtitle: 'Grey + Finishing',
                      isSelected: structureType == 'complete',
                      icon: Icons.home_rounded,
                      onTap: () => setState(() => structureType = 'complete'),
                    ),
                    const SizedBox(width: 10),
                    _buildOptionChip(
                      label: 'Grey Structure',
                      subtitle: 'Structure Only',
                      isSelected: structureType == 'grey',
                      icon: Icons.foundation_rounded,
                      onTap: () => setState(() => structureType = 'grey'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'Contract Execution Mode',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOptionChip(
                      label: 'With Material',
                      subtitle: 'Turnkey Supply',
                      isSelected: constructionMode == 'with_material',
                      icon: Icons.all_inclusive_rounded,
                      onTap: () => setState(() => constructionMode = 'with_material'),
                    ),
                    const SizedBox(width: 10),
                    _buildOptionChip(
                      label: 'Labor Only',
                      subtitle: 'Without Material',
                      isSelected: constructionMode == 'without_material',
                      icon: Icons.engineering_rounded,
                      onTap: () => setState(() => constructionMode = 'without_material'),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // Section 3: House Layout & Dimensions
              _buildSectionHeader('3. House Layout & Floors', Icons.stairs_rounded),
              _buildCardContainer([
                _buildCounterRow('Number of Floors', floors, (val) => setState(() => floors = val.clamp(1, 4))),
                const Divider(height: 20),
                _buildCounterRow('Bedrooms', bedrooms, (val) => setState(() => bedrooms = val.clamp(1, 10))),
                const Divider(height: 20),
                _buildCounterRow('Bathrooms', bathrooms, (val) => setState(() => bathrooms = val.clamp(1, 10))),
                const Divider(height: 20),
                _buildCounterRow('Kitchens', kitchens, (val) => setState(() => kitchens = val.clamp(0, 5))),
                const Divider(height: 20),
                _buildCounterRow('Drawing / Dining Rooms', drawingRooms, (val) => setState(() => drawingRooms = val.clamp(0, 4))),
              ]),
              const SizedBox(height: 24),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _calculateCost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dharttiGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calculate_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Calculate Estimated Cost',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: dharttiGreen),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? dharttiGreen.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? dharttiGreen : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? dharttiGreen : Colors.grey.shade600),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? dharttiGreen : Colors.black87,
                  ),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int count, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            InkWell(
              onTap: () => onChanged(count - 1),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.remove, size: 16, color: Colors.black87),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            InkWell(
              onTap: () => onChanged(count + 1),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: dharttiGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: dharttiGreen.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add, size: 16, color: dharttiGreen),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
