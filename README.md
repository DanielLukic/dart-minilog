## MiniLog - Minimal Log System

Just started Dart a few days ago. Looked for a logging package. There are several. But most are going beyond what I
needed to get started with my projects. So here is another one. But the name says it all: It is very minimalistic.

### What is this?

A very basic log system. Offering only some coarse grained log levels and basic log sinks: `print` or `fileSink`.
Custom log sinks can be implemented of course.

### How to use?

```dart
void main() {
  sink = fileSink("mini.log");
  //...
}

void somewhereElse() {
  logWarn("where am i?");
}
```

Output:

```
[W] where am i? [somewhereElse] (file://<snip>/dart-minilog/example/lib/example.dart:10:3)
```

### Caveat

This is used for the log output:

```dart
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
```

So, obviously, take this with a grain of salt... ☯
