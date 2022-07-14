import 'package:flutter/material.dart';

class ChangeNotifierBuilder extends StatefulWidget {
  final ChangeNotifier notifier;
  final WidgetBuilder builder;

  const ChangeNotifierBuilder({Key? key, required this.notifier, required this.builder}) : super(key: key);

  @override
  ChangeNotifierBuilderState createState() => ChangeNotifierBuilderState();
}

class ChangeNotifierBuilderState extends State<ChangeNotifierBuilder> {
  @override
  void initState() {
    widget.notifier.addListener(_listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}