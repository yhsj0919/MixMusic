import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  const SettingItem({super.key, this.margin, this.icon, this.title, this.subtitle, this.onTap, this.trailing});

  final EdgeInsetsGeometry? margin;
  final IconData? icon;
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
        leading: icon != null ? Icon(icon!) : null,
        title: title != null ? Text("$title") : null,
        subtitle: subtitle != null ? Text("$subtitle") : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
