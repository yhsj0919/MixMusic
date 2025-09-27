import 'package:flutter/material.dart';

typedef OffsetWidgetBuilder = Widget Function(double offset);

class SliverDelegate extends SliverPersistentHeaderDelegate {
  SliverDelegate({required this.builder, this.maxHeight, required this.minHeight, this.minWidget});

  final OffsetWidgetBuilder builder;
  final Widget? minWidget;
  final double? maxHeight;
  final double minHeight;

  double _offset = 0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    _offset = shrinkOffset < minHeight ? shrinkOffset : minHeight;

    var child = builder.call(shrinkOffset < minHeight ? shrinkOffset : minHeight);
    return SizedBox.expand(child: shrinkOffset == maxExtent ? (minWidget ?? child) : child);
  }

  @override
  double get maxExtent => maxHeight ?? minHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverDelegate oldDelegate) {
    // print('>>>>>>>>SliverDelegate  shouldRebuild触发了>>>>>>>>>>>>>>>>');
    var child = builder.call(_offset);

    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.builder || minWidget != oldDelegate.minWidget;
  }
}
