import 'package:flutter/material.dart';
import 'package:dhartti/Model/joinVenture.dart';
import 'package:dhartti/UserDashboard/Join%20Venture/venture_detail_screen.dart';

class VentureDetailScreens extends StatelessWidget {
  final JoinVenture venture;

  const VentureDetailScreens({Key? key, required this.venture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VentureDetailScreen(venture: venture);
  }
}
