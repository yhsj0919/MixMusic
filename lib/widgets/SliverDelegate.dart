import 'package:flutter/material.dart';

class SliverDelegate extends SliverPersistentHeaderDelegate {
  const SliverDelegate({required this.child, this.maxHeight, required this.minHeight, this.minWidget});

  final Widget child;
  final Widget? minWidget;
  final double? maxHeight;
  final double minHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: shrinkOffset == maxExtent ? (minWidget ?? child) : child);
  }

  @override
  double get maxExtent => maxHeight ?? minHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant SliverDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child || minWidget != oldDelegate.minWidget;
  }
}
