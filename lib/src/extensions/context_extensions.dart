import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ServerWidgetExtension on BuildContext {
  HttpAlt get http => Provider.of<HttpAlt>(this, listen: false);
}