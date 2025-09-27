import 'package:fluent_ui/fluent_ui.dart';

/// 自定义 Fluent 风格过渡的路由
class FluentRoute<T> extends PageRouteBuilder<T> {
  FluentRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOutCubic,
    Offset beginOffset = const Offset(0, 0.1), // 默认轻微上浮
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         opaque: true,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(parent: animation, curve: curve);

           // Slide 动画
           final slide = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved);

           return FadeTransition(
               opacity: curved, // 渐显渐隐
               child: child,

           );
         },
       );
}
