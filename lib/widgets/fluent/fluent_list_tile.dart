import 'package:fluent_ui/fluent_ui.dart';

class FluentListTile extends StatelessWidget {
  const FluentListTile({
    super.key,
    this.margin,
    this.leading,
    this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final EdgeInsetsGeometry? margin;
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final GestureTapCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Colors.black.withAlpha((255 * 0.1).toInt()), // 边框颜色
          width: 1, // 边框宽度
        ),
        borderRadius: BorderRadius.circular(5), // 圆角半径
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 8,vertical: 14),
        margin: EdgeInsets.zero,
        leading: leading,
        title: Text(title ?? "",style: FluentTheme.of(context).typography.body?.copyWith(fontWeight: FontWeight.w500),),
        subtitle: subtitle == null ? null : Text(subtitle ?? ""),
        trailing: trailing,
        onPressed: onTap,
      ),
    );
  }
}
