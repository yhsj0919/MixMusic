import 'package:flutter/material.dart';
import 'package:mix_music/theme/new_surface_theme.dart';
import 'package:mix_music/theme/surface_color_enum.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerPage extends StatelessWidget {
  const ShimmerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer.fromColors(
        baseColor: NewSurfaceTheme.getSurfaceColor(SurfaceColorEnum.surfaceContainerHighest, context),
        highlightColor: NewSurfaceTheme.getSurfaceColor(SurfaceColorEnum.surface, context),
        child: Column(
          children: List.generate(8, (index) {
            return Flexible(
                child: ListTile(
              leading: Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8), // 设置圆角
                  border: Border.all(width: 1),
                ),
              ),
              title: Container(
                margin: const EdgeInsets.only(bottom: 4),
                height: 25,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4), // 设置圆角
                ),
              ),
              subtitle: Container(
                height: 25,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4), // 设置圆角
                ),
              ),
            ));
          }),
        ),
      ),
    );
  }
}
