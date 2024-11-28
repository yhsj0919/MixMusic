import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HyperLoading extends StatelessWidget {
  const HyperLoading({
    super.key,
    this.width,
    this.height,
    this.size,
    this.color,
  });

  final double? width;
  final double? height;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: SpinKitFadingCube(
          color: color ?? Theme.of(context).colorScheme.primary,
          size: size ?? 25,
        ),
      ),
    );
  }
}
