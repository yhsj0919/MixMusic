import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:mix_music/theme/theme_controller.dart';

class HyperLoading extends StatefulWidget {
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
  State<HyperLoading> createState() => _HyperLoadingState();
}

class _HyperLoadingState extends State<HyperLoading> {
  ThemeController theme = Get.put(ThemeController());

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: CircularProgressIndicator(
          color: theme.mainColor.value ?? Theme.of(context).colorScheme.primary,
          year2023: false,
        ),
        // child: SpinKitFadingCube(
        //   color: color ?? Theme.of(context).colorScheme.primary,
        //   size: size ?? 25,
        // ),
      ),
    );
  }
}
