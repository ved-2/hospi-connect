import 'dart:async';

class AppLogger {
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void log(String msg) {
    // Keep stdout logging for debug builds
    // ignore: avoid_print
    print('DEBUG: $msg');
    _controller.add(msg);
  }
}
