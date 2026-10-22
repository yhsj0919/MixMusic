import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:lemon_x/lemon_x.dart';

import '../../common/download/download_controller.dart';
import '../../common/plugin/collection_controller.dart';

Future<void> downloadCollection(
  BuildContext context,
  CollectionController collection,
) async {
  final downloads = context.lx.find<DownloadController>();
  if (!context.mounted) return;
  downloads.addCollection(collection);
  context.go('/settings/downloads');
}
