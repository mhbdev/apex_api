import 'package:apex_api/apex_api.dart';
import 'package:flutter/material.dart';

class ConnectionBadge extends StatefulWidget {
  final HttpAlt server;
  final Locale locale;

  const ConnectionBadge({
    Key? key,
    required this.server,
    Locale? locale,
  })  : locale = locale ?? const Locale('fa', 'IR'),
        super(key: key);

  @override
  State<ConnectionBadge> createState() => _ConnectionBadgeState();
}

class _ConnectionBadgeState extends State<ConnectionBadge> {
  bool _hovered = false;

  Widget get _secureIcon => CircleAvatar(
        backgroundColor: Colors.grey.shade300.withOpacity(0.4),
        radius: 14,
        child: const Icon(
          Icons.verified_user,
          color: Colors.blue,
          size: 18,
        ),
      );

  bool get isFa => widget.locale.languageCode == 'fa';

  String get _connectedMessage => isFa ? 'اتصال امن' : 'Connected';

  String get _retryMessage => isFa ? 'تلاش مجدد' : 'Retry';

  String get _connectingInMessage => isFa
      ? 'اتصال در ${widget.server.elapsed} ثانیه'
      : 'Connecting in ${widget.server.elapsed} sec.';

  String get _connectingMessage => isFa ? 'در حال اتصال...' : 'Connecting...';

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w100);
    return MouseRegion(
      onEnter: (event) {
        _hovered = true;
        if (mounted) setState(() {});
      },
      onExit: (event) {
        _hovered = false;
        if (mounted) setState(() {});
      },
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: Center(
            child: Container(
          margin: const EdgeInsets.all(4),
          child: widget.server.isConnected
              ? (_hovered
                  ? SizedBox(
                      key: const ValueKey('fab-progress'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _secureIcon,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _connectedMessage,
                              style: textStyle,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _secureIcon)
              : SizedBox(
                  key: const ValueKey('fab-progress'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          key: ValueKey('connection-progress'),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                                '${widget.server.status == ConnectionStatus.connecting ? _connectingInMessage : _connectingMessage} ',
                                style: textStyle),
                            if (widget.server.status != ConnectionStatus.connecting)
                              GestureDetector(
                                onTap: () {
                                  widget.server.connectReset();
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Text(
                                    _retryMessage,
                                    style: textStyle.copyWith(fontSize: 15, color: Colors.blue),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        )),
      ),
    );
  }
}
