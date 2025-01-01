import 'package:flutter/material.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';

class MethodItem extends StatelessWidget {
  const MethodItem({super.key, this.modules, this.methods, this.onChipTap});

  final String? modules;
  final List<String>? methods;
  final Function(String key)? onChipTap;

  @override
  Widget build(BuildContext context) {
    return HyperGroup(
      inSliver: false,
      title: Text(modules ?? ""),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
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
        ),
      ],
    );
  }
}
