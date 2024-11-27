import 'package:flutter/material.dart';

class HyperAppbar extends StatelessWidget {
  const HyperAppbar({super.key, this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.medium(
      title: Text(title ?? "", style: Theme.of(context).appBarTheme.titleTextStyle),
      pinned: true,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                title ?? "",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 30),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
