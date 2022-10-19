import 'package:flutter/material.dart';

class MultiChangeNotifierBuilder extends StatefulWidget {
  final List<ChangeNotifier> notifiers;
  final WidgetBuilder builder;

  const MultiChangeNotifierBuilder({
    Key? key,
    required this.notifiers,
    required this.builder,
  }) : super(key: key);

  @override
  MultiChangeNotifierBuilderState createState() => MultiChangeNotifierBuilderState();
}

class MultiChangeNotifierBuilderState extends State<MultiChangeNotifierBuilder> {
  @override
  void initState() {
    for (var notifier in widget.notifiers) {
      notifier.addListener(_listener);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (var notifier in widget.notifiers) {
      notifier.removeListener(_listener);
    }
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
