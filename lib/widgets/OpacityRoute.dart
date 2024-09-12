import 'package:flutter/material.dart';

class OpacityRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  OpacityRoute({required this.builder})
      : super(
          //kThemeAnimationDuration
          transitionDuration: kThemeAnimationDuration,
          reverseTransitionDuration: kThemeAnimationDuration,
          transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
            return Opacity(opacity: animation.value, child: child);
          },
          pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
            return Opacity(opacity: animation.value, child: builder.call(context));
          },
        );
}
