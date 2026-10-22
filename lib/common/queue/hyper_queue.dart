import 'package:lemon_x/lemon_x.dart';

import 'hyper_queue_entry.dart';
import 'hyper_queue_source.dart';

class _QueueNode<T> {
  _QueueNode({this.item, this.source});
  T? item;
  final HyperQueueSource<T>? source;
  final children = <_QueueNode<T>>[];
  int read = 0;
  void Function()? listener;
  Future<void>? pending;
  bool suspended = false;
}

class HyperQueue<T> extends LxController implements LxDisposable {
  HyperQueue({required this.same, required this.snapshot});
  final bool Function(T, T) same;
  final T Function(T) snapshot;
  late final items = own(Rx<List<T>>([]));
  late final entries = own(Rx<List<HyperQueueEntry<T>>>([]));
  late final roots = own(Rx<List<HyperQueueEntry<T>>>([]));
  late final index = own((-1).obs);
  late final error = own(''.obs);
  final _roots = <_QueueNode<T>>[];
  List<_QueueNode<T>> _flat = [];
  HyperQueueSource<T>? blockedSource;

  Iterable<_QueueNode<T>> _walk(List<_QueueNode<T>> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _walk(node.children);
    }
  }

  _QueueNode<T>? get _current => index.value < 0 ? null : _flat[index.value];
  bool get hasMore => _sequence().any((node) => node.source != null);

  void _refresh([_QueueNode<T>? current]) {
    current ??= _current;
    final rows = <HyperQueueEntry<T>>[];
    final flat = <_QueueNode<T>>[];
    void visit(List<_QueueNode<T>> nodes) {
      for (final node in nodes) {
        if (node.item != null) {
          flat.add(node);
          rows.add(HyperQueueEntry(item: node.item));
        } else {
          visit(node.children);
          final source = node.source!;
          if (node.suspended ||
              source.hasMore.value ||
              source.error.value.isNotEmpty) {
            rows.add(
              HyperQueueEntry(source: source, suspended: node.suspended),
            );
          }
        }
      }
    }

    visit(_roots);
    _flat = flat;
    index.value = current == null ? -1 : flat.indexOf(current);
    items.value = flat.map((node) => node.item as T).toList();
    entries.value = rows;
    roots.value = [
      for (final node in _roots)
        HyperQueueEntry(
          item: node.item,
          source: node.source,
          suspended: node.suspended,
        ),
    ];
  }

  List<T> itemsIn(Object key) {
    final node = _walk(_roots)
        .where((node) => node.source?.key == key)
        .firstOrNull;
    if (node == null) return [];
    return _walk(node.children)
        .where((node) => node.item != null)
        .map((node) => node.item as T)
        .toList();
  }

  List<_QueueNode<T>> _parent(_QueueNode<T> target) {
    for (final node in _walk(_roots)) {
      if (node.children.contains(target)) return node.children;
    }
    return _roots;
  }

  _QueueNode<T>? _find(T item) {
    for (final node in _walk(_roots)) {
      if (node.item != null && same(node.item as T, item)) return node;
    }
    return null;
  }

  int append(T item) {
    final existing = _find(item);
    if (existing != null) return _flat.indexOf(existing);
    final node = _QueueNode(item: snapshot(item));
    _roots.add(node);
    _refresh();
    return _flat.indexOf(node);
  }

  int insertNext(T item) {
    final current = _current;
    final node = _find(item) ?? _QueueNode(item: snapshot(item));
    if (node == current) return index.value;
    _parent(node).remove(node);
    final parent = current == null ? _roots : _parent(current);
    parent.insert(current == null ? 0 : parent.indexOf(current) + 1, node);
    _refresh(current);
    return _flat.indexOf(node);
  }

  void replace(int position, T item) {
    _flat[position].item = snapshot(item);
    _refresh();
  }

  void appendCollection(HyperQueueSource<T> source, {bool next = false}) {
    if (_walk(_roots).any((node) => node.source?.key == source.key)) return;
    final node = _QueueNode<T>(source: source);
    final current = _current;
    final parent = next && current != null ? _parent(current) : _roots;
    parent.insert(
      next
          ? (current == null ? 0 : parent.indexOf(current) + 1)
          : parent.length,
      node,
    );
    void changed() {
      if (!isDisposed) _sync(node);
    }

    node.listener = changed;
    source.items.addListener(changed);
    source.hasMore.addListener(changed);
    source.error.addListener(changed);
    _sync(node);
  }

  void insertNextCollection(HyperQueueSource<T> source) =>
      appendCollection(source, next: true);

  void _sync(_QueueNode<T> node) {
    for (final item in node.source!.items.value.skip(node.read)) {
      if (_find(item) == null) {
        node.children.add(_QueueNode(item: snapshot(item)));
      }
    }
    node.read = node.source!.items.value.length;
    _refresh();
  }

  Future<void> _load(_QueueNode<T> node, bool retry) async {
    final source = node.source!;
    if (!retry && source.error.value.isNotEmpty) {
      blockedSource = source;
      error.value = source.error.value;
      return;
    }
    error.value = '';
    blockedSource = null;
    try {
      await (node.pending ??= source.loadMore().whenComplete(
        () => node.pending = null,
      ));
      if (isDisposed || node.suspended || !_walk(_roots).contains(node)) return;
      _sync(node);
      error.value = source.error.value;
      if (error.value.isNotEmpty) blockedSource = source;
    } catch (exception) {
      if (!isDisposed && !node.suspended && _walk(_roots).contains(node)) {
        source.error.value = '$exception';
        error.value = '$exception';
        blockedSource = source;
      }
    }
  }

  // 未展开的集合是顺序屏障，不能越过它播放后面已加载的内容。
  List<_QueueNode<T>> _sequence() {
    final result = <_QueueNode<T>>[];
    void visit(List<_QueueNode<T>> nodes) {
      for (final node in nodes) {
        if (node.suspended) continue;
        if (node.item != null) {
          result.add(node);
        } else {
          visit(node.children);
          if (node.source!.hasMore.value) result.add(node);
        }
      }
    }

    visit(_roots);
    return result;
  }

  Future<void> loadMore({bool viewing = false, bool retry = false}) async {
    final sequence = _sequence();
    final current = _current;
    final start = viewing || current == null
        ? 0
        : sequence.indexOf(current) + 1;
    for (var i = start; i < sequence.length; i++) {
      final node = sequence[i];
      if (node.source != null) {
        if (viewing || i - start <= 2) await _load(node, retry);
        return;
      }
    }
  }

  Future<int?> nextIndex({bool retry = false}) async {
    error.value = '';
    blockedSource = null;
    final current = _current;
    while (!isDisposed) {
      final sequence = _sequence();
      final position = current == null ? 0 : sequence.indexOf(current) + 1;
      if (position >= sequence.length) return null;
      final node = sequence[position];
      if (node.item != null) return _flat.indexOf(node);
      final before = node.read;
      await _load(node, retry);
      if (isDisposed || _current != current || !_walk(_roots).contains(node)) {
        return null;
      }
      if (node.suspended) continue;
      if (error.value.isNotEmpty ||
          (node.source!.hasMore.value && node.read == before)) {
        return null;
      }
    }
    return null;
  }

  Future<int?> collectionIndex(Object key) async {
    final node = _walk(_roots)
        .where((node) => node.source?.key == key)
        .firstOrNull;
    if (node == null) return null;
    if (node.children.isEmpty && node.source!.hasMore.value) {
      await _load(node, false);
    }
    if (isDisposed || !_walk(_roots).contains(node)) return null;
    final first = _walk(node.children)
        .where((node) => node.item != null)
        .firstOrNull;
    return first == null ? null : _flat.indexOf(first);
  }

  void suspend(Object key) => _setSuspended(key, true);
  void resume(Object key) => _setSuspended(key, false);

  void _setSuspended(Object key, bool value) {
    final node = _walk(_roots)
        .where((node) => node.source?.key == key)
        .firstOrNull;
    if (node == null) return;
    node.suspended = value;
    if (blockedSource?.key == key) {
      blockedSource = null;
      error.value = '';
    }
    _refresh();
  }

  void _detach(_QueueNode<T> node) {
    for (final child in node.children) {
      _detach(child);
    }
    final source = node.source;
    final listener = node.listener;
    if (source == null || listener == null) return;
    source.items.removeListener(listener);
    source.hasMore.removeListener(listener);
    source.error.removeListener(listener);
  }

  void remove(int position) {
    final node = _flat[position];
    final parent = _parent(node);
    parent.remove(node);
    if (parent.isEmpty && !identical(parent, _roots)) {
      final source = _walk(_roots)
          .firstWhere((item) => identical(item.children, parent));
      _detach(source);
      _parent(source).remove(source);
    }
    _refresh();
  }

  void removeCollection(Object key) {
    final node = _walk(_roots)
        .where((node) => node.source?.key == key)
        .firstOrNull;
    if (node == null) return;
    _detach(node);
    _parent(node).remove(node);
    _refresh();
  }

  void removeWhere(
    bool Function(T) test, {
    bool Function(HyperQueueSource<T>)? source,
  }) {
    void remove(List<_QueueNode<T>> nodes) {
      for (final node in nodes.toList()) {
        if (node.item != null
            ? test(node.item as T)
            : source?.call(node.source!) ?? false) {
          _detach(node);
          nodes.remove(node);
        } else {
          remove(node.children);
        }
      }
    }

    remove(_roots);
    _refresh();
  }

  void clear() {
    for (final node in _roots) {
      _detach(node);
    }
    _roots.clear();
    _refresh();
    blockedSource = null;
    error.value = '';
  }

  @override
  Future<void> dispose() => disposeController();
  @override
  void onDispose() {
    for (final node in _roots) {
      _detach(node);
    }
    _roots.clear();
  }
}
