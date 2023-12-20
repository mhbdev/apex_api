import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../clients/base_connection.dart';

extension ServerWidgetExtension on BuildContext {
  BaseConnection get connection => Provider.of<BaseConnection>(this, listen: false);

  @Deprecated("Use [context.connection] instead")
  HttpAlt get http => Provider.of<HttpAlt>(this, listen: false);

  @Deprecated("Use [context.connection] instead")
  HttpAlt get api => Provider.of<HttpAlt>(this, listen: false);
}
