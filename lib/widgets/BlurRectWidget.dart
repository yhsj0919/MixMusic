import 'dart:ui';

/// describe
/// 高斯模糊效果合集
/// created by hujintao
/// created at 2019-09-12
//
import 'package:flutter/material.dart';

/// 矩形高斯模糊效果
class BlurRectWidget extends StatefulWidget {
  final Widget? child;

  final double? height;
  final double? width;

  /// 模糊值
  final double? sigmaX;
  final double? sigmaY;

  /// 透明度
  final double? opacity;

  /// 外边距
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  /// 圆角
  final BorderRadius borderRadius;

  ///边框
  final BoxBorder? border;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const BlurRectWidget({
    Key? key,
    this.width,
    this.height,
    this.child,
    this.sigmaX,
    this.sigmaY,
    this.opacity,
    this.margin,
    this.padding,
    this.border,
    this.color,
    this.boxShadow,
    this.borderRadius = BorderRadius.zero,
  }) : super(key: key);

  @override
  _BlurRectWidgetState createState() => _BlurRectWidgetState();
}

class _BlurRectWidgetState extends State<BlurRectWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.sigmaX ?? 10,
            sigmaY: widget.sigmaY ?? 10,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              border: widget.border ?? Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1)),
              borderRadius: widget.borderRadius,
              color: widget.color ?? (Theme.of(context).brightness == Brightness.light ? Colors.white10 : Colors.black12),
              boxShadow: widget.boxShadow,
            ),
            child: widget.opacity != null ? Opacity(opacity: widget.opacity ?? 0.5, child: widget.child) : widget.child,
          ),
        ),
      ),
    );
  }
}
