import 'dart:async';

class Debounce<T> {
  final Duration delay;
  Timer? _timer;
  Completer<T>? _completer;

  Debounce({required this.delay});

  Future<T> run(FutureOr<T> Function() action) {
    _timer?.cancel();
    _completer = Completer<T>();

    _timer = Timer(delay, () async {
      if (!_completer!.isCompleted) {
        _completer!.complete(await action());
      }
    });

    return _completer!.future;
  }

  void dispose() {
    _timer?.cancel();
  }
}