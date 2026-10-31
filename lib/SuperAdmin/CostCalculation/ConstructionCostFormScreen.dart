import 'package:dhartti/Model/ConstructionCostModel.dart';
import 'package:dhartti/service/construction_cost_service.dart';
import 'package:flutter/material.dart';

class ConstructionCostFormScreen extends StatefulWidget {
  final ConstructionCostModel? model;

  ConstructionCostFormScreen({this.model});

  @override
  _ConstructionCostFormScreenState createState() => _ConstructionCostFormScreenState();
}

class _ConstructionCostFormScreenState extends State<ConstructionCostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController greyCtrl = TextEditingController();
  final TextEditingController finishCtrl = TextEditingController();
  final TextEditingController labourWithCtrl = TextEditingController();
  final TextEditingController labourWithoutCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.model != null) {
      cityCtrl.text = widget.model!.city;
      greyCtrl.text = widget.model!.greyStructureMaterial.toString();
      finishCtrl.text = widget.model!.finishingMaterial.toString();
      labourWithCtrl.text = widget.model!.labourWithMaterial.toString();
      labourWithoutCtrl.text = widget.model!.labourWithoutMaterial.toString();
      priceCtrl.text = widget.model!.pricePerSqft.toString();
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final model = ConstructionCostModel(
      id: widget.model?.id,
      city: cityCtrl.text,
      userId: widget.model?.userId ?? 1, // ideally should come from auth
      greyStructureMaterial: double.parse(greyCtrl.text),
      finishingMaterial: double.parse(finishCtrl.text),
      labourWithMaterial: double.parse(labourWithCtrl.text),
      labourWithoutMaterial: double.parse(labourWithoutCtrl.text),
      pricePerSqft: double.parse(priceCtrl.text),
    );

    if (widget.model == null) {
      await ConstructionCostService.create(model);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added successfully")));
    } else {
      await ConstructionCostService.update(widget.model!.id!, model);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Updated successfully")));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model == null ? "Add Cost" : "Edit Cost")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(cityCtrl, "City"),
              _buildField(greyCtrl, "Grey Structure", isNumber: true),
              _buildField(finishCtrl, "Finishing Material", isNumber: true),
              _buildField(labourWithCtrl, "Labour with Material", isNumber: true),
              _buildField(labourWithoutCtrl, "Labour without Material", isNumber: true),
              _buildField(priceCtrl, "Price Per Sqft", isNumber: true),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text(widget.model == null ? "Add" : "Update")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
