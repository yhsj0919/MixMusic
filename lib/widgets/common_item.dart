import 'package:flutter/material.dart';

class CommonItem extends StatelessWidget {
  const CommonItem({super.key, this.margin, this.child});

  final EdgeInsetsGeometry? margin;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}
