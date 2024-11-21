import 'package:flutter/material.dart';

class HyperGroup extends StatelessWidget {
  const HyperGroup({super.key, this.children = const <Widget>[], this.title, this.inSliver = true});

  final List<Widget> children;
  final String? title;
  final bool inSliver;

  @override
  Widget build(BuildContext context) {
    var child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          title != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        style: Theme.of(context).textTheme.labelMedium ?? TextStyle(),
                        duration: kThemeChangeDuration,
                        child: Text(title ?? ""),
                      ),
                      Expanded(child: Container()),
                      // Text(
                      //   "刷新",
                      //   style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                      // ),
                    ],
                  ))
              : Container(),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: children,
              ),
            ),
          )
        ],
      ),
    );

    return inSliver ? SliverToBoxAdapter(child: child) : child;
  }
}
