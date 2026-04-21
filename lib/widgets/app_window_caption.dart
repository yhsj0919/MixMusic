import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AppWindowCaption extends StatefulWidget {
  final Widget? title;
  final Color? backgroundColor;
  final Brightness? brightness;

  const AppWindowCaption({
    Key? key,
    this.title,
    this.backgroundColor,
    this.brightness,
  }) : super(key: key);

  @override
  State<AppWindowCaption> createState() => _AppWindowCaptionState();
}

class _AppWindowCaptionState extends State<AppWindowCaption>
    with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        DragToMoveArea(
          child: Container(
            height: kWindowCaptionHeight,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.only(left: 16, right: 138),
            child: DefaultTextStyle(
              maxLines: 1,
              style: TextStyle(
                color: widget.brightness == Brightness.light
                    ? Colors.black.withOpacity(0.8956)
                    : Colors.white,
                fontSize: 14,
              ),
              child: widget.title ?? Container(),
            ),
          ),
        ),
        Container(
          width: 138,
          color: widget.brightness == Brightness.dark
              ? Color(0x00202020)
              : Colors.transparent,
          height: kWindowCaptionHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: WindowCaptionButton.minimize(
                  brightness: widget.brightness,
                  onPressed: () async {
                    bool isMinimized = await windowManager.isMinimized();
                    if (isMinimized) {
                      windowManager.restore();
                    } else {
                      windowManager.minimize();
                    }
                  },
                ),
              ),
              Flexible(
                child: FutureBuilder<bool>(
                  future: windowManager.isMaximized(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.data == true) {
                          return WindowCaptionButton.unmaximize(
                            brightness: widget.brightness,
                            onPressed: () {
                              windowManager.unmaximize();
                            },
                          );
                        }
                        return WindowCaptionButton.maximize(
                          brightness: widget.brightness,
                          onPressed: () {
                            windowManager.maximize();
                          },
                        );
                      },
                ),
              ),
              Flexible(
                child: WindowCaptionButton.close(
                  brightness: widget.brightness,
                  onPressed: () {
                    windowManager.close();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void onWindowMaximize() {
    setState(() {});
  }

  @override
  void onWindowUnmaximize() {
    setState(() {});
  }
}
