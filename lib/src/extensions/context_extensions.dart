import 'package:flutter/material.dart';

import '../server_widget.dart';

extension ServerWidgetExtension on BuildContext {
  ServerWrapperState get api => ServerWidget.of(this, build: false);
}