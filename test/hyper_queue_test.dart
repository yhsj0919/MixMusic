import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon_x/lemon_x.dart';
import 'package:mix_music/common/queue/hyper_queue.dart';
import 'package:mix_music/common/queue/hyper_queue_source.dart';

class Feed {
  Feed(this.start, this.count, {bool loaded = false, this.pageSize = 3}) {
    if (loaded) {
      items.value = [for (var i = 0; i < min(pageSize, count); i++) start + i];
      hasMore.value = count > pageSize;
    }
  }
  final int start;
  final int count;
  final int pageSize;
  final items = Rx<List<int>>([]);
  final hasMore = true.obs;
  final error = ''.obs;
  Completer<void>? gate;
  bool fail = false;
  int calls = 0;
  HyperQueueSource<int> get source => HyperQueueSource(
    key: this,
    title: 'feed-$start',
    items: items,
    hasMore: hasMore,
    error: error,
    loadMore: loadMore,
  );
  Future<void> loadMore() async {
    calls++;
    error.value = '';
    await gate?.future;
    if (fail) {
      error.value = '分页失败';
      return;
    }
    final offset = items.value.length;
    hasMore.value = offset + pageSize < count;
    items.value = [
      ...items.value,
      for (var i = offset; i < min(offset + pageSize, count); i++) start + i,
    ];
  }

  void dispose() {
    items.dispose();
    hasMore.dispose();
    error.dispose();
  }
}

void main() {
  late HyperQueue<int> queue;
  late Feed a;
  late Feed b;
  setUp(() {
    queue = HyperQueue(same: (a, b) => a == b, snapshot: (item) => item);
    a = Feed(0, 6, loaded: true);
    b = Feed(100, 4);
  });
  tearDown(() async {
    await queue.dispose();
    a.dispose();
    b.dispose();
  });

  test(
    '100-song A keeps all its pages before the appended song and unloaded B',
    () async {
      final large = Feed(0, 100, loaded: true, pageSize: 20);
      final later = Feed(1000, 40, pageSize: 20);
      addTearDown(large.dispose);
      addTearDown(later.dispose);
      queue.appendCollection(large.source);
      queue.append(999);
      queue.appendCollection(later.source);
      expect(queue.items.value.length, 21);
      expect(later.calls, 0);
      queue.index.value = 19;
      final first = await queue.nextIndex();
      expect(queue.items.value[first!], 20);
      for (var i = 0; i < 3; i++) {
        await queue.loadMore(viewing: true);
      }
      expect(queue.items.value, [...List.generate(100, (i) => i), 999]);
      expect(later.calls, 0);
      queue.index.value = 100;
      final second = await queue.nextIndex();
      expect(queue.items.value[second!], 1000);
      expect(later.calls, 1);
    },
  );

  test(
    'append registers unloaded B; A pages stay before the manual song and B',
    () async {
      queue.appendCollection(a.source);
      queue.append(99);
      queue.appendCollection(b.source);
      expect(a.calls, 0);
      expect(b.calls, 0);
      expect(queue.entries.value.last.source!.key, b);
      queue.index.value = 2;
      final next = await queue.nextIndex();
      expect(queue.items.value, [0, 1, 2, 3, 4, 5, 99]);
      expect(queue.items.value[next!], 3);
      expect(b.calls, 0);
      queue.index.value = 5;
      expect(queue.items.value[(await queue.nextIndex())!], 99);
      queue.index.value = 6;
      final bIndex = await queue.nextIndex();
      expect(queue.items.value[bIndex!], 100);
      expect(b.calls, 1);
    },
  );

  test(
    'insert next collection resumes A after B and keeps later pages in A',
    () async {
      queue.appendCollection(a.source);
      queue.append(99);
      queue.index.value = 1;
      queue.insertNextCollection(b.source);
      expect(b.calls, 0);
      var next = await queue.nextIndex();
      expect(queue.items.value[next!], 100);
      queue.index.value = next;
      for (final expected in [101, 102, 103, 2, 3]) {
        next = await queue.nextIndex();
        expect(queue.items.value[next!], expected);
        queue.index.value = next;
      }
      expect(queue.items.value, [0, 1, 100, 101, 102, 103, 2, 3, 4, 5, 99]);
    },
  );

  test(
    'source failure is a barrier; explicit retry uses the same source',
    () async {
      queue.appendCollection(a.source);
      queue.appendCollection(b.source);
      queue.index.value = 2;
      a.fail = true;
      expect(await queue.nextIndex(), isNull);
      expect(queue.error.value, '分页失败');
      expect(b.calls, 0);
      expect(await queue.nextIndex(), isNull);
      expect(a.calls, 1);
      a.fail = false;
      final retryIndex = await queue.nextIndex(retry: true);
      expect(queue.items.value[retryIndex!], 3);
      expect(a.calls, 2);
    },
  );

  test(
    'view and boundary merge requests; clearing cannot refill the queue',
    () async {
      queue.appendCollection(a.source);
      queue.index.value = 2;
      a.gate = Completer<void>();
      final viewing = queue.loadMore(viewing: true);
      final boundary = queue.nextIndex();
      expect(a.calls, 1);
      queue.clear();
      a.gate!.complete();
      await viewing;
      expect(await boundary, isNull);
      expect(queue.items.value, isEmpty);
      expect(queue.entries.value, isEmpty);
    },
  );

  test('insert next song remains before pending A pages, current cursor stays stable', () async {
    queue.appendCollection(a.source);
    queue.index.value = 2;
    a.gate = Completer<void>();
    final loading = queue.loadMore(viewing: true);
    queue.insertNext(88);
    a.gate!.complete();
    await loading;
    expect(queue.index.value, 2);
    expect(queue.items.value, [0, 1, 2, 88, 3, 4, 5]);
    expect(queue.items.value[(await queue.nextIndex())!], 88);
  });

  test(
    'empty source ends naturally; removing an unloaded source makes no request',
    () async {
      final empty = Feed(200, 0);
      addTearDown(empty.dispose);
      queue.appendCollection(empty.source);
      queue.appendCollection(b.source);
      queue.removeCollection(b);
      queue.append(99);
      expect(queue.items.value[(await queue.nextIndex())!], 99);
      expect(empty.calls, 1);
      expect(b.calls, 0);
    },
  );
}
