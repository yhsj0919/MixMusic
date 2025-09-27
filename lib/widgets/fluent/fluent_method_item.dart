import 'package:fluent_ui/fluent_ui.dart';
import 'package:mix_music/widgets/fluent/fluent_group.dart';
import 'package:mix_music/widgets/hyper/hyper_group.dart';

class FluentMethodItem extends StatelessWidget {
  const FluentMethodItem({
    super.key,
    this.modules,
    this.methods,
    this.onChipTap,
  });

  final String? modules;
  final List<String>? methods;
  final Function(String key)? onChipTap;

  @override
  Widget build(BuildContext context) {
    return FluentGroup(
      inSliver: false,
      title: Text(modules ?? ""),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                methods?.map((label) {
                  return Button(
                    onPressed: onChipTap == null
                        ? null
                        : () {
                            onChipTap?.call(label);
                          },
                    child: Text(label),
                  );
                }).toList() ??
                [],
          ),
        ),
      ],
    );
  }
}
