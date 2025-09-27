import 'package:fluent_ui/fluent_ui.dart';

typedef MouseWidgetBuilder = Widget Function(bool hover);

class FluentMouseWidget extends StatefulWidget {
  const FluentMouseWidget({super.key, required this.builder});

  final MouseWidgetBuilder builder;

  @override
  State<FluentMouseWidget> createState() => _FluentMouseWidgetState();
}

class _FluentMouseWidgetState extends State<FluentMouseWidget> {
  bool onUp = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          onUp = true;
        });
      },
      onExit: (_) {
        setState(() {
          onUp = false;
        });
      },
      child: widget.builder.call(onUp),
    );
  }
}
