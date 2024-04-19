import 'dart:io';

import 'package:ansi/ansi.dart';

/// Create a *synchronous*(!) file sink.
fileSink(String filename, {bool truncate = false, int maxSizeBytes = 1000000}) {
  final file = File(filename);
  if (truncate && file.existsSync()) file.deleteSync();
  var parent = Directory(filename).parent;
  if (!parent.existsSync()) parent.createSync();
  return (e) {
    final file = File(filename);
    if (!file.existsSync()) file.createSync();
    final ts = DateTime.timestamp().toIso8601String();
    final msg = "$ts $e\n";
    file.writeAsString(msg, mode: FileMode.append);
    if (file.lengthSync() > maxSizeBytes) file.renameSync("$filename.bak");
  };
}

/// Define where log messages should go. This can be anything that is a
/// `void Function(Object?)`. If, for example, you need async logging, you could
/// dispatch via a custom sink into some [StreamController] of yours and go
/// from there. Or if you need custom log levels per context, a custom sink can
/// handle this.
var sink = print;

/// One [LogLevel] for everything.
var logLevel = LogLevel.info;

/// Toggle ANSI coloring in log output. You can of course strip ANSI in your
/// sink and/or turn it off here and add your own ANSI in your custom sink.
var logAnsi = true;

/// The available log levels. [LogLevel.info] should be considered the default.
enum LogLevel { verbose, debug, info, warn, error, none }

extension on LogLevel {
  /// Single uppercase letter representing the log level.
  tag() => name.substring(0, 1).toUpperCase();
}

/// Generic log call. Will use [LogLevel.Info] if [level] is null. Will print
/// the [trace] *after* the message if non-null. If the [message] is `null`,
/// then `null` will be printed. If [message] is a `Function`, it will be
/// evaluate here without arguments. On failure, [logError] will be called.
log(Object? message, [LogLevel? level, StackTrace? trace]) {
  level ??= LogLevel.info;
  if (level.index < logLevel.index) return;

  var (name, where) = StackTrace.current.caller;
  if (message is Function) {
    try {
      message = message();
    } catch (it, trace) {
      logError(it, trace);
      return;
    }
  }

  var full = "[${level.tag()}] $message [$name] $where";
  if (logAnsi) full = _ansify(full, level);
  sink(full);

  if (trace != null) sink(trace.toString());
}

String _ansify(String full, LogLevel level) => switch (level) {
      LogLevel.verbose => gray(full),
      LogLevel.debug => cyan(full),
      LogLevel.info => green(full),
      LogLevel.warn => magenta(full),
      LogLevel.error => red(full),
      LogLevel.none => full,
    };

/// Log [message] and [trace] using [LogLevel.error]. The rules from [log]
/// apply.
logError(Object? message, [StackTrace? trace]) =>
    log(message, LogLevel.error, trace);

/// Log [message] using [LogLevel.warn]. The rules from [log] apply.
logWarn(Object? message) => log(message, LogLevel.warn);

/// Log [message] using [LogLevel.info]. The rules from [log] apply.
logInfo(Object? message) => log(message, LogLevel.info);

/// Log [message] using [LogLevel.debug]. The rules from [log] apply.
logDebug(Object? message) => log(message, LogLevel.debug);

/// Log [message] using [LogLevel.verbose]. The rules from [log] apply.
logVerbose(Object? message) => log(message, LogLevel.verbose);

extension StackTraceCallerExtension on StackTrace {
  /// Determine the call site for a [StackTrace]. Obviously prone to fail
  /// outside development setup.
  (String function, String location) get caller {
    caller(String it) => !it.contains("log.dart");
    var lines = toString().split("\n");
    var trace = lines.firstWhere(caller, orElse: () => "");
    var parts = trace.replaceAll(RegExp(r"#\d\s+"), "").split(" ");
    return (parts[0], parts[1]);
  }
}
