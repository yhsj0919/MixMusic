import 'dart:async';
import 'dart:isolate';

/// 任务定义：支持同步 / async
typedef IsolateTask<P, R> = FutureOr<R> Function(P param);

/// Isolate 返回结果协议（成功 / 失败）
class IsolateResult<R> {
  final R? data;
  final String? error;
  final String? stack;

  const IsolateResult._({
    this.data,
    this.error,
    this.stack,
  });

  factory IsolateResult.success(R data) {
    return IsolateResult._(data: data);
  }

  factory IsolateResult.failure(Object error, StackTrace stack) {
    return IsolateResult._(
      error: error.toString(),
      stack: stack.toString(),
    );
  }

  bool get isSuccess => error == null;
}

/// Isolate 内部消息
class _IsolateMessage<P, R> {
  final P param;
  final IsolateTask<P, R> task;
  final SendPort sendPort;

  const _IsolateMessage({
    required this.param,
    required this.task,
    required this.sendPort,
  });
}

/// Isolate 工具类
class IsolateUtil {
  IsolateUtil._();

  /// 对外唯一 API
  static Future<R> run<P, R>(
      P param,
      IsolateTask<P, R> task,
      ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn<_IsolateMessage<P, R>>(
      _entryPoint,
      _IsolateMessage<P, R>(
        param: param,
        task: task,
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as IsolateResult<R>;
    receivePort.close();

    if (result.isSuccess) {
      return result.data as R;
    } else {
      throw IsolateException(result.error!, result.stack);
    }
  }

  /// Isolate 入口
  static Future<void> _entryPoint<P, R>(
      _IsolateMessage<P, R> message,
      ) async {
    try {
      final value = await message.task(message.param);
      message.sendPort.send(IsolateResult.success(value));
    } catch (e, s) {
      message.sendPort.send(IsolateResult.failure(e, s));
    }
  }
}

/// 自定义异常（方便区分 Isolate 错误）
class IsolateException implements Exception {
  final String message;
  final String? stack;

  IsolateException(this.message, this.stack);

  @override
  String toString() {
    return 'IsolateException: $message\n$stack';
  }
}
