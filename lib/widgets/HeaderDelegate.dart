import 'package:flutter/material.dart';

class HeaderDelegate extends SliverPersistentHeaderDelegate {
  const HeaderDelegate({required this.child, this.childMaxExtent, required this.childMinExtent, this.minWidget});

  final Widget child;
  final Widget? minWidget;
  final double? childMaxExtent;
  final double childMinExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    print(shrinkOffset);

    return shrinkOffset == maxExtent ? (minWidget ?? child) : child;
  }

  @override
  double get maxExtent => childMaxExtent ?? childMinExtent;

  @override
  double get minExtent => childMinExtent;

  @override
  bool shouldRebuild(covariant HeaderDelegate oldDelegate) => false;
}
