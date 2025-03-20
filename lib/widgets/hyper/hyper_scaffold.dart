import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/widgets/ext.dart';

class HyperScaffold extends StatefulWidget {
  const HyperScaffold({
    Key? key,
    this.backgroundColor,
    this.leftWidth = 400,
    this.centerWidth = 400,
    this.left,
    this.floatingActionButton,
    this.center,
  }) : super(key: key);

  final Color? backgroundColor;
  final double leftWidth;
  final double? centerWidth;
  final Widget? left;
  final Widget? floatingActionButton;

  final Widget? center;

  @override
  _HyperScaffoldState createState() => _HyperScaffoldState();
}

class _HyperScaffoldState extends State<HyperScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      floatingActionButton: widget.floatingActionButton,
      body: Row(children: [
        SizedBox(
          width: widget.leftWidth.autoValue(
              condition: widget.center == null || context.width < widget.leftWidth + 300, def: context.width),
          child: widget.left,
        ),
        Container(
          width: (context.width < 1600) ? null : widget.centerWidth,
          child: widget.center,
        )
            .flexible(enable: context.width < 1300)
            .autoValue(condition: context.width < widget.leftWidth + 300, def: Container()),
      ]),
    );
  }
}
