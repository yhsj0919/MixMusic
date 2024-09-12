import 'package:flutter/material.dart';

class MethodItem extends StatelessWidget {
  const MethodItem({super.key, this.margin, this.img, this.modules, this.methods, this.onTap, this.trailing, this.onChipTap});

  final EdgeInsetsGeometry? margin;
  final String? img;
  final String? modules;
  final List<String>? methods;
  final GestureTapCallback? onTap;
  final Widget? trailing;
  final Function(String key)? onChipTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 圆角半径
        ),
        leading: img != null
            ? Image.network(
                img!,
                width: 50,
                height: 50,
              )
            : null,
        trailing: trailing,
        title: modules != null ? Text("$modules") : null,
        subtitle: methods?.isNotEmpty == true
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  runSpacing: 8,
                  spacing: 8,
                  children: methods?.map((label) {
                        return ActionChip(
                          label: Text(label),
                          onPressed: onChipTap == null
                              ? null
                              : () {
                                  onChipTap?.call(label);
                                },
                        );
                      }).toList() ??
                      [],
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
