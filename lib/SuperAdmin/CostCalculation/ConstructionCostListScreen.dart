import 'package:dhartti/Model/ConstructionCostModel.dart';
import 'package:dhartti/SuperAdmin/CostCalculation/ConstructionCostFormScreen.dart';
import 'package:dhartti/service/construction_cost_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ConstructionCostListScreen extends StatefulWidget {
  @override
  _ConstructionCostListScreenState createState() => _ConstructionCostListScreenState();
}

class _ConstructionCostListScreenState extends State<ConstructionCostListScreen> {
  late Future<List<ConstructionCostModel>> _futureCosts;
  final Color _primaryColor = Color(0xFF2E7D32); // Darker green
  final Color _accentColor = Color(0xFF4CAF50); // Lighter green
  final Color _backgroundColor = Color(0xFFF5F5F5); // Light grey background
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadCosts();
  }

  void _loadCosts() {
    _futureCosts = ConstructionCostService.getAll();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: TextStyle(color: _primaryColor)),
        content: Text('Are you sure you want to delete this construction cost?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );

    if (confirmed == true) {
      try {
        await ConstructionCostService.delete(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Deleted successfully"),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _loadCosts());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting item"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goToForm({ConstructionCostModel? model}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConstructionCostFormScreen(model: model),
      ),
    );
    setState(() => _loadCosts());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.building,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              "No Construction Costs Found",
              style: TextStyle(
                fontSize: 22,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Start by adding your first construction cost data",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _goToForm(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  "Add New Cost",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(ConstructionCostModel item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _goToForm(model: item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.city,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "PKR ${item.pricePerSqft}/sqft",
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildDetailRow("Grey Structure", "PKR ${item.greyStructureMaterial}/sqft"),
              _buildDetailRow("Finishing Material", "PKR ${item.finishingMaterial}/sqft"),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: _primaryColor),
                    onPressed: () => _goToForm(model: item),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[400]),
                    onPressed: () => _delete(item.id!),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "Construction Costs",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<ConstructionCostModel>>(
          future: _futureCosts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      "Error loading data",
                      style: TextStyle(fontSize: 18, color: _textColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCosts,
                      child: Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (_, index) => _buildCostItem(snapshot.data![index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(),
        child: Icon(Icons.add, size: 28),
        backgroundColor: _primaryColor,
        elevation: 4,
        tooltip: 'Add New Cost',
      ),
    );
  }
}
