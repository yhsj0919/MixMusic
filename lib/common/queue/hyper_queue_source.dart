import 'package:lemon_x/lemon_x.dart';

class HyperQueueSource<T> {
  HyperQueueSource({
    required this.key,
    required this.title,
    required this.items,
    required this.hasMore,
    required this.error,
    required this.loadMore,
  });
  final Object key;
  final String title;
  final Rx<List<T>> items;
  final Rx<bool> hasMore;
  final Rx<String> error;
  final Future<void> Function() loadMore;
}
