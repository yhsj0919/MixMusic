import 'package:flutter/material.dart';

class HyperAppbar1 extends StatelessWidget {
  const HyperAppbar1({super.key, this.title, this.bottom, this.actions, this.forceElevated = false});

  final String? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool forceElevated;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.medium(
      title: Text(title ?? "", style: Theme.of(context).appBarTheme.titleTextStyle),
      pinned: true,
      actions: actions,
      forceElevated: forceElevated,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
          collapseMode: CollapseMode.pin,
          background: Stack(
            children: [
              Container(
                alignment: Alignment.bottomLeft,
                margin: EdgeInsets.only(bottom: bottom?.preferredSize.height ?? 0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  title ?? "",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 30),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )),
    );
  }
}
