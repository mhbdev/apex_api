import 'package:flutter/material.dart';

mixin MountedStateMixin<T extends StatefulWidget> on State<T> {
  void mountedSetState([VoidCallback? fn]) {
    if (mounted) {
      setState(fn ?? () {});
    }
  }
}

mixin WidgetLoadMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => onLoad(context));

    super.initState();
  }

  void onLoad(BuildContext context);
}
