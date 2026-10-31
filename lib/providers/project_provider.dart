import 'package:dhartti/Model/project_model.dart';
import 'package:dhartti/service/project_service.dart';
import 'package:flutter/material.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _apiService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> fetchProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _apiService.fetchProjects();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
