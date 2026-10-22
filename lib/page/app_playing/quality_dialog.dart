import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../../common/entity/quality.dart';

Future<int?> selectQuality(
  BuildContext context,
  List<Quality> qualities, {
  bool showSize = true,
}) => showHyperDialog<int>(
  context: context,
  builder: (context) => HyperDialog(
    title: const HyperText('选择音质'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in qualities)
          HyperListTile(
            title: HyperText(item.title),
            subtitle: showSize && item.size != null
                ? HyperText('${item.size}')
                : null,
            onTap: () => context.pop(item.value),
          ),
      ],
    ),
  ),
);
