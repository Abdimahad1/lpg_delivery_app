import 'package:flutter/material.dart';

class BackHandlerWrapper extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onBack;

  const BackHandlerWrapper({
    Key? key,
    required this.child,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBack ?? () async => true, // Default: allow back
      child: child,
    );
  }
}
