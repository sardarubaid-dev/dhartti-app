import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum MarlaStandard {
  society225(225.0, '225 Sq. Ft (Societies / DHA / LDA)'),
  revenue272(272.25, '272.25 Sq. Ft (Govt / Revenue)'),
  cda250(250.0, '250 Sq. Ft (Islamabad / CDA)');

  final double sqFt;
  final String label;
  const MarlaStandard(this.sqFt, this.label);
}

class AreaConverterScreen extends StatefulWidget {
  const AreaConverterScreen({super.key});

  @override
  State<AreaConverterScreen> createState() => _AreaConverterScreenState();
}

class _AreaConverterScreenState extends State<AreaConverterScreen> {
  final TextEditingController _inputController = TextEditingController(text: '1');
  String _fromUnit = 'kanal';
  String _toUnit = 'marla';
  MarlaStandard _marlaStandard = MarlaStandard.society225;

  final Map<String, String> _unitLabels = {
    'marla': 'Marla',
    'kanal': 'Kanal',
    'square_feet': 'Square Feet (Sq. Ft)',
    'square_yards': 'Square Yards (Sq. Yd / Gaz)',
    'square_meters': 'Square Meters (Sq. M)',
    'acre': 'Acre (Kila)',
    'murabba': 'Murabba',
    'hectare': 'Hectare',
  };

  final Map<String, String> _shortUnitLabels = {
    'marla': 'Marla',
    'kanal': 'Kanal',
    'square_feet': 'Sq. Ft',
    'square_yards': 'Sq. Yd',
    'square_meters': 'Sq. M',
    'acre': 'Acre',
    'murabba': 'Murabba',
    'hectare': 'Hectare',
  };

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  double _getUnitInSqFt(String unit) {
    final marlaSqFt = _marlaStandard.sqFt;
    switch (unit) {
      case 'square_feet':
        return 1.0;
      case 'square_yards':
        return 9.0;
      case 'square_meters':
        return 10.7639;
      case 'marla':
        return marlaSqFt;
      case 'kanal':
        return marlaSqFt * 20.0;
      case 'acre':
        return marlaSqFt * 20.0 * 8.0; // 8 Kanals
      case 'murabba':
        return marlaSqFt * 20.0 * 8.0 * 25.0; // 25 Acres
      case 'hectare':
        return 107639.104; // 10,000 sq m
      default:
        return 1.0;
    }
  }

  double _convert(double value, String from, String to) {
    final sqFt = value * _getUnitInSqFt(from);
    return sqFt / _getUnitInSqFt(to);
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
  }

  void _applyQuickPreset(double value, String unit) {
    setState(() {
      _inputController.text = value % 1 == 0 ? value.toInt().toString() : value.toString();
      _fromUnit = unit;
    });
  }

  String _formatNumber(double val) {
    if (val.abs() >= 10000000) {
      return (val / 10000000).toStringAsFixed(3) + ' Cr';
    } else if (val.abs() >= 100000) {
      return (val / 100000).toStringAsFixed(2) + ' Lakh';
    } else if (val.abs() >= 1000) {
      return val.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else if (val % 1 == 0) {
      return val.toInt().toString();
    } else if (val.abs() < 0.001) {
      return val.toStringAsExponential(2);
    } else {
      return val.toStringAsFixed(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputValue = double.tryParse(_inputController.text.trim()) ?? 0.0;
    final convertedValue = inputValue > 0 ? _convert(inputValue, _fromUnit, _toUnit) : 0.0;
    final primaryColor = const Color(0xFF108224);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Area Unit Converter',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Standard Selection Card (Pakistan Real Estate Context)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Marla Standard in Pakistan',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<MarlaStandard>(
                              value: _marlaStandard,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                              items: MarlaStandard.values.map((std) {
                                return DropdownMenuItem(
                                  value: std,
                                  child: Text(
                                    std.label,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _marlaStandard = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Interactive Converter Main Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Input Field
                        Text(
                          'Enter Area Value',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _inputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 5',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            suffixIcon: _inputController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () => _inputController.clear(),
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Unit Selectors & Swap Button
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  _buildUnitDropdown('Convert From', _fromUnit, (val) {
                                    if (val != null) setState(() => _fromUnit = val);
                                  }),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: IconButton.filled(
                                      style: IconButton.styleFrom(
                                        backgroundColor: primaryColor,
                                      ),
                                      icon: const Icon(Icons.swap_vert_rounded, color: Colors.white),
                                      onPressed: _swapUnits,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildUnitDropdown('Convert To', _toUnit, (val) {
                                    if (val != null) setState(() => _toUnit = val);
                                  }),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _buildUnitDropdown('Convert From', _fromUnit, (val) {
                                    if (val != null) setState(() => _fromUnit = val);
                                  }),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Material(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _swapUnits,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(Icons.swap_horiz_rounded, color: primaryColor, size: 24),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildUnitDropdown('Convert To', _toUnit, (val) {
                                    if (val != null) setState(() => _toUnit = val);
                                  }),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prominent Result Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF0B5E1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CONVERSION RESULT',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 1,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final textToCopy = '${_formatNumber(inputValue)} ${_shortUnitLabels[_fromUnit]} = ${_formatNumber(convertedValue)} ${_shortUnitLabels[_toUnit]}';
                                Clipboard.setData(ClipboardData(text: textToCopy));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied "$textToCopy" to clipboard'),
                                    backgroundColor: Colors.black87,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatNumber(convertedValue),
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _unitLabels[_toUnit] ?? _toUnit,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_formatNumber(inputValue)} ${_shortUnitLabels[_fromUnit]} is equal to ${_formatNumber(convertedValue)} ${_shortUnitLabels[_toUnit]}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Instant Complete Unit Breakdown Table
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dashboard_customize_outlined, size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Instant Multi-Unit Breakdown',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Equivalent values for ${_formatNumber(inputValue)} ${_shortUnitLabels[_fromUnit]}:',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _unitLabels.keys.map((unitKey) {
                            final val = inputValue > 0 ? _convert(inputValue, _fromUnit, unitKey) : 0.0;
                            final isCurrentTarget = unitKey == _toUnit;
                            return Container(
                              width: (MediaQuery.of(context).size.width > 500) ? 290 : double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCurrentTarget ? primaryColor.withOpacity(0.08) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrentTarget ? primaryColor.withOpacity(0.3) : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _shortUnitLabels[unitKey] ?? unitKey,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: isCurrentTarget ? FontWeight.bold : FontWeight.w500,
                                      color: isCurrentTarget ? primaryColor : Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    _formatNumber(val),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentTarget ? primaryColor : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Popular Real Estate Presets
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 20, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Popular Pakistan Plot Sizes',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip('3 Marla', () => _applyQuickPreset(3, 'marla')),
                            _buildPresetChip('5 Marla', () => _applyQuickPreset(5, 'marla')),
                            _buildPresetChip('7 Marla', () => _applyQuickPreset(7, 'marla')),
                            _buildPresetChip('10 Marla', () => _applyQuickPreset(10, 'marla')),
                            _buildPresetChip('1 Kanal', () => _applyQuickPreset(1, 'kanal')),
                            _buildPresetChip('2 Kanal', () => _applyQuickPreset(2, 'kanal')),
                            _buildPresetChip('1 Acre (8 Kanal)', () => _applyQuickPreset(1, 'acre')),
                            _buildPresetChip('500 Sq. Yds', () => _applyQuickPreset(500, 'square_yards')),
                            _buildPresetChip('225 Sq. Ft', () => _applyQuickPreset(225, 'square_feet')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: _unitLabels.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF108224)),
      backgroundColor: const Color(0xFF108224).withOpacity(0.08),
      side: BorderSide(color: const Color(0xFF108224).withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }
}
