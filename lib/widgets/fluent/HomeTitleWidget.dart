import 'package:fluent_ui/fluent_ui.dart';

class HomeTitleWidget extends StatefulWidget {
  const HomeTitleWidget({
    super.key,
    required this.title,
    this.onTapTitle,
    this.onTapLeft,
    this.onTapRight,
  });

  final Widget title;
  final GestureTapCallback? onTapTitle;
  final GestureTapCallback? onTapLeft;
  final GestureTapCallback? onTapRight;

  @override
  State<HomeTitleWidget> createState() => _HomeTitleWidgetState();
}

class _HomeTitleWidgetState extends State<HomeTitleWidget> {
  bool onUp = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MouseRegion(
          onEnter: (_) {
            if (widget.onTapTitle != null) {
              setState(() {
                onUp = true;
              });
            }
          },
          onExit: (_) {
            if (widget.onTapTitle != null) {
              setState(() {
                onUp = false;
              });
            }
          },
          child: IconButton(
            onPressed: widget.onTapTitle,
            icon: Builder(
              builder: (context) {
                return AnimatedPadding(
                  padding: EdgeInsetsDirectional.only(
                    start: onUp ? 16.0 : 0,
                    end: onUp ? 16.0 : 0,
                  ),
                  duration: Duration(milliseconds: 150),
                  child: DefaultTextStyle(
                    style: FluentTheme.of(context).typography.subtitle!,
                    child: widget.title,
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(child: Container()),
        // Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(
        //       color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
        //       width: 1, // 边框宽度
        //     ),
        //     borderRadius: BorderRadius.circular(5), // 圆角半径
        //   ),
        //   child: IconButton(
        //     icon: Icon(FluentIcons.chevron_left, size: 16),
        //     onPressed: widget.onTapLeft,
        //   ),
        // ),
        // Gap(6),
        // Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(
        //       color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
        //       width: 1, // 边框宽度
        //     ),
        //     borderRadius: BorderRadius.circular(5), // 圆角半径
        //   ),
        //   child: IconButton(
        //     icon: Icon(FluentIcons.chevron_right, size: 16),
        //     onPressed: widget.onTapRight,
        //   ),
        // ),
      ],
    );
  }
}
