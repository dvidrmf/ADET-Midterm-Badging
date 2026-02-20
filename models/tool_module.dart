import 'package:flutter/material.dart';

abstract class ToolModule {
  String get title;
  IconData get icon;
  Widget buildBody(BuildContext context);
}
