import 'hyper_queue_source.dart';

class HyperQueueEntry<T> {
  HyperQueueEntry({this.item, this.source, this.suspended = false});
  final T? item;
  final HyperQueueSource<T>? source;
  final bool suspended;
}
