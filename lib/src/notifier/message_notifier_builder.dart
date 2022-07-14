import 'package:flutter/material.dart';

import '../typedefs.dart';
import 'message_notifier.dart';

class MessageNotifierBuilder extends StatefulWidget {
  final MessageNotifier notifier;
  final NotifierWidgetBuilder builder;
  final List<String> tags;

  const MessageNotifierBuilder({
    Key? key,
    required this.tags,
    required this.notifier,
    required this.builder,
  }) : super(key: key);

  @override
  MessageNotifierBuilderState createState() => MessageNotifierBuilderState();
}

class MessageNotifierBuilderState extends State<MessageNotifierBuilder> {
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

  void _listener(String tag, [dynamic message]) {
    if(widget.tags.contains(tag)) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }
}
