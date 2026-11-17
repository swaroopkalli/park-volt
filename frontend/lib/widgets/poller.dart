import 'dart:async';

import 'package:flutter/widgets.dart';

/// Calls [onTick] every [interval] while mounted.
class Poller extends StatefulWidget {
  const Poller({super.key, required this.interval, required this.onTick, required this.child});
  final Duration interval;
  final VoidCallback onTick;
  final Widget child;
  @override
  State<Poller> createState() => _PollerState();
}

class _PollerState extends State<Poller> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.interval, (_) => widget.onTick());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
