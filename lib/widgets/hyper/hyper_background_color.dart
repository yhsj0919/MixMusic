import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:mix_music/theme/theme_controller.dart';

class HyperBackgroundColor extends StatefulWidget {
  const HyperBackgroundColor({super.key, this.child, this.color});

  final Widget? child;
  final Color? color;

  @override
  State<HyperBackgroundColor> createState() => _HyperBackgroundColorState();
}

class _HyperBackgroundColorState extends State<HyperBackgroundColor> {
  @override
  Widget build(BuildContext context) {
    var page = AnimatedContainer(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 渐变的开始位置
            end: Alignment.bottomCenter, // 渐变的结束位置
            stops: [0.25, 0.7],
            colors: [
              Theme.of(context).colorScheme.surface,
              NewSurfaceTheme.getSurfaceColorWithSeed(SurfaceColorEnum.surfaceContainer, widget.color ?? Theme.of(context).colorScheme.primary, context),
            ], // 渐变的颜色
          ),
        ),
        duration: Duration(milliseconds: 500),
        child: widget.child);

    return page;
  }
}
