import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/ext.dart';

class HyperScaffold extends StatefulWidget {
  const HyperScaffold({
    Key? key,
    this.menu,
    this.leftWidth = 400,
    this.centerWidth = 400,
    this.rightWidth = 350,
    this.minWidth,
    this.left,
    this.floatingActionButton,
    this.center,
    this.right,
  }) : super(key: key);

  final Widget? menu;
  final double leftWidth;
  final double? centerWidth;
  final double? rightWidth;
  final double? minWidth;
  final Widget? left;
  final Widget? floatingActionButton;

  final Widget? center;
  final Widget? right;

  @override
  _HyperScaffoldState createState() => _HyperScaffoldState();
}

class _HyperScaffoldState extends State<HyperScaffold> {
  double horizontalPadding = 0.0;
  final verticalPadding = 0.0;

  @override
  Widget build(BuildContext context) {
    horizontalPadding = (context.width < widget.leftWidth + 300 || context.width < (widget.minWidth ?? 0)) ? 8 : 20;

    return Scaffold(
      // backgroundColor: Colors.transparent,
      appBar: widget.menu != null ? PreferredSize(preferredSize: const Size(double.infinity, 1000), child: widget.menu!) : null,
      body: Row(children: [
        SizedBox(
          width: widget.leftWidth.autoValue(
              condition: (widget.center == null && widget.right == null) || (context.width < widget.leftWidth + 300 || context.width < (widget.minWidth ?? 0)),
              def: context.width - horizontalPadding * 2),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.left,
            floatingActionButton: widget.floatingActionButton,
          ),
        ),
        Container(
          width: (widget.right == null || context.width < 1300) ? null : widget.centerWidth,
          margin: widget.center == null ? null : EdgeInsets.only(left: horizontalPadding),
          child: widget.center,
        )
            .flexible(enable: widget.right == null || context.width < 1300)
            .autoValue(condition: (context.width < widget.leftWidth + 300 || context.width < (widget.minWidth ?? 0)), def: Container()),
        Container(
          width: widget.centerWidth != null ? null : widget.rightWidth,
          margin: widget.right == null ? null : EdgeInsets.only(left: horizontalPadding),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.right,
            floatingActionButton: widget.floatingActionButton,
          ),
        ).flexible(enable: widget.centerWidth != null).autoValue(condition: context.width < 1300 || widget.right == null, def: Container()),
      ]),
    );
  }
}
