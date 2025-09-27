import 'package:fluent_ui/fluent_ui.dart';

class FluentGroup extends StatelessWidget {
  const FluentGroup({
    super.key,
    this.children = const <Widget>[],
    this.title,
    this.inSliver = true,
    this.trailing,
    // this.alpha = 0.7,
    this.horizontalPadding = 24,
  });

  final List<Widget> children;
  final Widget? title;
  final Widget? trailing;
  final bool inSliver;

  // final double? alpha;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    var child = Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          title != null
              ? Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      DefaultTextStyle(style: FluentTheme.of(context).typography.bodyStrong?.copyWith(fontSize: 16) ?? TextStyle(), child: title!),
                      Expanded(child: Container()),
                      trailing != null ? trailing! : Container(),
                      // Text(
                      //   "刷新",
                      //   style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                      // ),
                    ],
                  ),
                )
              : Container(),
          Column(children: children),
        ],
      ),
    );

    return inSliver ? SliverToBoxAdapter(child: child) : child;
  }
}
