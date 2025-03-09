import 'dart:async';

/// 防抖工具类
/// 用于防止某些操作在短时间内被频繁触发
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// 执行函数，如果在延迟时间内再次调用，则取消之前的任务
  void run(Function action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      action();
    });
  }

  /// 立即执行，并取消之前的任务
  void runNow(Function action) {
    _timer?.cancel();
    action();
  }

  /// 取消计划中的任务
  void cancel() {
    _timer?.cancel();
  }

  /// 销毁定时器
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
} 