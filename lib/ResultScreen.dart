import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class CostResultsScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const CostResultsScreen({Key? key, required this.result}) : super(key: key);

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    final greyColors = [
      const Color(0xFF4e73df),
      const Color(0xFF1cc88a),
      const Color(0xFF36b9cc),
      const Color(0xFFf6c23e),
      const Color(0xFFe74a3b),
      const Color(0xFF858796),
    ];

    final double totalCost = _toDouble(result['total_cost']);
    final double coveredArea = _toDouble(result['covered_area']);
    final double greyCost = _toDouble(result['grey_cost']);
    final double finishCost = _toDouble(result['finish_cost']);
    final double labourCost = _toDouble(result['labour_cost']);
    final double pricePerSqft = _toDouble(result['price_per_sqft']);

    final Map<dynamic, dynamic> inputs = (result['inputs'] is Map) ? result['inputs'] : {};

    final String structureType = inputs['structure_type']?.toString().toLowerCase() == 'grey'
        ? 'Grey Structure'
        : 'Complete House';
    final String constructionMode = inputs['construction_mode']?.toString().toLowerCase() == 'with_material'
        ? 'With Material'
        : 'Without Material';
    final String city = inputs['city']?.toString() ?? 'Pakistan';
    final String plotArea = '${inputs['area'] ?? ''} ${inputs['unit'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF108224),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Construction Cost Estimate',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Construction Cost Estimate',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF051A53),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Summary Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.45,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSummaryCard(
                  'Total Estimated Cost',
                  'PKR ${formatter.format(totalCost)}',
                  'For ${formatter.format(coveredArea)} Sq.ft',
                  const Color(0xFF051A53),
                ),
                _buildSummaryCard(
                  'Grey Structure Cost',
                  'PKR ${formatter.format(greyCost)}',
                  totalCost > 0
                      ? '${((greyCost / totalCost) * 100).toStringAsFixed(1)}% of total'
                      : '0% of total',
                  const Color(0xFFffc107),
                ),
                if (finishCost > 0)
                  _buildSummaryCard(
                    'Finishing Cost',
                    'PKR ${formatter.format(finishCost)}',
                    totalCost > 0
                        ? '${((finishCost / totalCost) * 100).toStringAsFixed(1)}% of total'
                        : '0% of total',
                    const Color(0xFF17a2b8),
                  ),
                _buildSummaryCard(
                  'Labour Cost',
                  'PKR ${formatter.format(labourCost)}',
                  totalCost > 0
                      ? '${((labourCost / totalCost) * 100).toStringAsFixed(1)}% of total'
                      : '0% of total',
                  const Color(0xFF28a745),
                ),
                _buildSummaryCard(
                  'Price per SqFt',
                  'PKR ${formatter.format(pricePerSqft)}',
                  'Based on covered area',
                  const Color(0xFF4e73df),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pie Chart Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Share Breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF051A53),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: PieChart(
                      PieChartData(
                        sections: _buildChartSections(result, greyColors, totalCost, finishCost, labourCost),
                        centerSpaceRadius: 50,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Project Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Details',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF051A53),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Construction Type:', structureType),
                  _buildDetailRow('Construction Mode:', constructionMode),
                  _buildDetailRow('Location:', city),
                  if (plotArea.isNotEmpty) _buildDetailRow('Plot Area:', plotArea),
                  _buildDetailRow('Total Covered Area:', '${formatter.format(coveredArea)} Sq.ft'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cost Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost Breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF051A53),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildBreakdownItems(result, greyColors, formatter, totalCost, finishCost),
                  _buildBreakdownItem(
                    'Labour',
                    labourCost,
                    totalCost,
                    const Color(0xFF5a5c69),
                    formatter,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Construction Notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The estimated cost is based on prevailing market rates in $city for a $structureType ($constructionMode). Actual expenses may fluctuate depending on material grade, site conditions, and contractor schedule.',
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1E40AF), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(
    Map<String, dynamic> result,
    List<Color> greyColors,
    double totalCost,
    double finishCost,
    double labourCost,
  ) {
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    final rawBreakdown = result['breakdown_data'];
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((label, rawData) {
        if (rawData is Map) {
          final double lakhVal = _toDouble(rawData['lakh']);
          final double percentVal = _toDouble(rawData['percent']);
          if (lakhVal > 0) {
            sections.add(
              PieChartSectionData(
                color: greyColors[colorIndex % greyColors.length],
                value: lakhVal,
                title: percentVal > 0 ? '${percentVal.toStringAsFixed(0)}%' : '',
                radius: 55,
                titleStyle: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
            colorIndex++;
          }
        }
      });
    }

    if (finishCost > 0) {
      final finishLakh = finishCost / 100000;
      final finishPercent = totalCost > 0 ? ((finishCost / totalCost) * 100).toStringAsFixed(0) : '0';
      sections.add(
        PieChartSectionData(
          color: const Color(0xFFe74a3b),
          value: finishLakh,
          title: '$finishPercent%',
          radius: 55,
          titleStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (labourCost > 0) {
      final labourLakh = labourCost / 100000;
      final labourPercent = totalCost > 0 ? ((labourCost / totalCost) * 100).toStringAsFixed(0) : '0';
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF5a5c69),
          value: labourLakh,
          title: '$labourPercent%',
          radius: 55,
          titleStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF108224),
          value: 100,
          title: '100%',
          radius: 55,
          titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return sections;
  }

  Widget _buildSummaryCard(String title, String value, String subtext, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreakdownItems(
    Map<String, dynamic> result,
    List<Color> colors,
    NumberFormat formatter,
    double totalCost,
    double finishCost,
  ) {
    final items = <Widget>[];
    int colorIndex = 0;

    final rawBreakdown = result['breakdown_data'];
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((label, rawData) {
        if (rawData is Map) {
          final double lakhVal = _toDouble(rawData['lakh']);
          items.add(
            _buildBreakdownItem(
              label.toString(),
              lakhVal * 100000,
              totalCost,
              colors[colorIndex % colors.length],
              formatter,
            ),
          );
          colorIndex++;
        }
      });
    }

    if (finishCost > 0) {
      items.add(
        _buildBreakdownItem(
          'Finishing',
          finishCost,
          totalCost,
          const Color(0xFFe74a3b),
          formatter,
        ),
      );
    }

    return items;
  }

  Widget _buildBreakdownItem(String label, dynamic costVal, dynamic totalVal, Color color, NumberFormat formatter) {
    final double cost = _toDouble(costVal);
    final double total = _toDouble(totalVal);
    final String percent = total > 0 ? ((cost / total) * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF334155)),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$percent%',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(width: 6),
              Text(
                '(PKR ${formatter.format(cost)})',
                style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
