import 'package:flutter/material.dart';

class PluginItem extends StatelessWidget {
  const PluginItem({super.key, this.margin, this.leading, this.title, this.subtitle, this.onTap, this.trailing});

  final EdgeInsetsGeometry? margin;
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final GestureTapCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 圆角半径
        ),
        leading: leading,
        trailing: trailing,
        title: title != null ? Text("$title") : null,
        subtitle: subtitle != null ? Text("$subtitle") : null,
        onTap: onTap,
      ),
    );
  }
}
